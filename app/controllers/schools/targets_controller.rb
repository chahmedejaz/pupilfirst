module Schools
  class TargetsController < SchoolsController
    before_action :load_new_target, only: %w[create]
    before_action :load_target, only: %w[update]

    # POST /school/target_groups/:target_group_id/targets(.:format)
    def create
      form = ::Schools::Targets::CreateOrUpdateForm.new(@target)

      if form.validate(params[:target])
        target = form.save
        render json: { id: target.id, sortIndex: target.sort_index, error: nil }
      else
        render json: { error: form.errors.full_messages.join(', ') }
      end
    end

    # PATCH /school/targets/:id
    def update
      form = ::Schools::Targets::CreateOrUpdateForm.new(@target)

      if form.validate(params[:target])
        target = form.save
        render json: { id: target.id.to_s, sortIndex: target.sort_index, error: nil }
      else
        render json: { error: form.errors.full_messages.join(', ') }
      end
    end

    # GET /school/targets/:id/content
    def content
      render json: camelize_keys(stringify_ids(Targets::FetchContentService.new(@target).details))
    end

    protected

    def load_new_target
      @target_group = TargetGroup.find(params[:target_group_id])
      @target = authorize(Target.new(target_group: @target_group), policy_class: Schools::TargetPolicy)
    end

    def load_target
      @target = authorize(Target.find(params[:id]), policy_class: Schools::TargetPolicy)
    end
  end
end
