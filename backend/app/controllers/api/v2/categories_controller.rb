module Api
  module V2
    class CategoriesController < ApplicationController
      def index
        categories = Category.where(active: true).order(:name)
        render json: categories.map { |category| category_response(category) }
      end

      private

      def category_response(category)
        {
          id: category.id,
          name: category.name,
          auto_approve_limit: category.auto_approve_limit
        }
      end
    end
  end
end
