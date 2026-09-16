require "csv"

module Api
  module V1
    module Admin
      class ReportsController < AdminController
        def show
          from, to = report_dates
          expenses = Expense.includes(:category).where(spent_date: from..to).where(state: report_states)
          report = report_response(expenses, from, to)

          if request.format.csv?
            send_data report_csv(report[:rows]), filename: "expense-report-#{from}-to-#{to}.csv", type: "text/csv"
          else
            render json: report
          end
        rescue Date::Error, ArgumentError
          render json: { error: "Invalid report date range" }, status: :unprocessable_entity
        end

        private

        def report_dates
          raise Date::Error if params[:from].blank? || params[:to].blank?

          from = Date.iso8601(params[:from])
          to = Date.iso8601(params[:to])
          raise ArgumentError if from > to

          [from, to]
        end

        def report_states
          params[:state].present? && Expense.states.key?(params[:state]) ? params[:state] : [:approved, :reimbursed]
        end

        def report_response(expenses, from, to)
          rows = expenses.group_by { |expense| [expense.spent_date.strftime("%Y-%m"), expense.category.name] }.map do |(month, category), grouped|
            approved = grouped.select(&:approved?)
            reimbursed = grouped.select(&:reimbursed?)
            {
              month: month,
              category: category,
              approved_count: approved.length,
              approved_amount: approved.sum { |expense| expense.amount.to_d },
              reimbursed_count: reimbursed.length,
              reimbursed_amount: reimbursed.sum { |expense| expense.amount.to_d }
            }
          end.sort_by { |row| [row[:month], row[:category]] }

          {
            generated_at: Time.current,
            filters: { from: from.iso8601, to: to.iso8601, state: params[:state] },
            rows: rows,
            summary: {
              total_expenses: rows.sum { |row| row[:approved_count] + row[:reimbursed_count] },
              total_amount: rows.sum { |row| row[:approved_amount] + row[:reimbursed_amount] }
            }
          }
        end

        def report_csv(rows)
          CSV.generate do |csv|
            csv << ["Month", "Category", "Approved count", "Approved amount", "Reimbursed count", "Reimbursed amount"]
            rows.each { |row| csv << [row[:month], row[:category], row[:approved_count], row[:approved_amount], row[:reimbursed_count], row[:reimbursed_amount]] }
          end
        end
      end
    end
  end
end