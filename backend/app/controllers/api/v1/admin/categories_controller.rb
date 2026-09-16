module Api
  module V1
    module Admin
      class CategoriesController < AdminController
        def index
          categories, meta = pagination(Category.order(sort_column => sort_direction))
          render json: { categories: categories.map { |category| category_response(category) }, pagination: meta }
        end

        def create
          category = Category.new(category_params)
          if category.save
            render json: category_response(category), status: :created
          else
            render_validation_errors(category)
          end
        end

        def update
          category = Category.find(params[:id])
          if category.update(category_params)
            render json: category_response(category)
          else
            render_validation_errors(category)
          end
        end

        private

        def category_params
          params.require(:category).permit(:name, :auto_approve_limit, :active)
        end

        def sort_column
          %w[name auto_approve_limit active created_at].include?(params[:sort]) ? params[:sort] : "name"
        end

        def sort_direction
          params[:direction] == "desc" ? :desc : :asc
        end

        def category_response(category)
          { id: category.id, name: category.name, auto_approve_limit: category.auto_approve_limit, active: category.active }
        end
      end
    end
  end
end