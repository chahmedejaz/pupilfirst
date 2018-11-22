module Founders
  class DashboardDataService
    def initialize(founder)
      @founder = founder
    end

    def props
      {
        targets: targets,
        levels: levels_as_json,
        faculty: faculty,
        targetGroups: target_groups,
        tracks: tracks
      }
    end

    private

    def targets
      # Targets at or below startup's level
      applicable_targets = Target.live.joins(target_group: :level).where(target_groups: { level: open_levels }).includes(:faculty)

      # Load basic data about targets from database.
      loaded_targets = applicable_targets.as_json(
        only: target_fields,
        include: {
          target_group: { only: :id },
          faculty: { only: :id }
        }
      )

      # Add additional data that cannot be directly queried to each target.
      loaded_targets.map do |target|
        dashboard_decorated_data(target)
      end
    end

    def visible_levels
      @visible_levels ||= startup.level_zero? ? startup.course.levels.where(number: 0) : startup.course.levels.where('levels.number >= ?', 1)
    end

    def open_levels
      @open_levels ||= visible_levels.where(unlock_on: nil).or(visible_levels.where('unlock_on <= ?', Date.today))
    end

    def levels_as_json
      visible_levels.as_json(
        only: %i[id name number],
        methods: :unlocked
      )
    end

    def faculty
      Faculty.team.all.as_json(
        only: %i[id name],
        methods: :image_url
      )
    end

    def target_groups
      TargetGroup.joins(:level).where(level: open_levels)
        .as_json(
          only: %i[id name description milestone sort_index],
          include: { track: { only: :id }, level: { only: :id } }
        )
    end

    def tracks
      Track.all.as_json(only: %i[id name sort_index])
    end

    def dashboard_decorated_data(target_data)
      # Add status of target to compiled data.
      target_data['status'] = target_status_service.status(target_data['id'])

      # Add time of submission of last event, necessary for submitted and completed state.
      if target_data['status'].in?([Target::STATUS_SUBMITTED, Target::STATUS_COMPLETE])
        target_data['submitted_at'] = target_status_service.submitted_at(target_data['id'])
      end

      # add grade and score if completed
      target_data['grade'] = target_grade_service.grade(target_data['id']) if target_data['status'] == Target::STATUS_COMPLETE
      target_data['score'] = target_grade_service.score(target_data['id']) if target_data['status'] == Target::STATUS_COMPLETE

      # add array of prerequisites
      target_data['prerequisites'] = target_status_service.prerequisite_targets(target_data['id'])

      target_data
    end

    def target_status_service
      @target_status_service ||= Founders::TargetStatusService.new(@founder)
    end

    def target_grade_service
      @target_grade_service ||= Founders::TargetGradeService.new(@founder)
    end

    def startup
      @startup ||= @founder.startup
    end

    def target_fields
      %i[id role title description completion_instructions resource_url slideshow_embed video_embed youtube_video_id days_to_complete points_earnable session_at session_by link_to_complete submittability archived call_to_action sort_index]
    end
  end
end
