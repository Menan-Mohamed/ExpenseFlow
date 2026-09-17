import { useEffect, useState } from "react";
import { ExpenseForm } from "../components/ExpenseForm";
import { ExpenseList } from "../components/ExpenseList";
import { AdminPagination, AdminTable } from "../components/AdminTable";
import {
  getCategories,
  type Category,
  type Expense,
  type ExpenseDetails,
  type ExpenseInput,
} from "../services/expenses";
import {
  approveManagerExpense,
  createManagerExpense,
  deleteManagerExpense,
  getManagerExpense,
  getManagerExpenses,
  getManagerMembers,
  getManagerReview,
  getManagerReviews,
  rejectManagerExpense,
  reopenManagerExpense,
  submitManagerExpense,
  updateManagerExpense,
  type ManagerMember,
  type ManagerReviewDetails,
  type ManagerReviewExpense,
} from "../services/manager";
import { ProfileButton } from "../components/ProfileButton";
import { NotificationButton } from "../components/NotificationButton";
import {
  ExpenseFilters,
  type ExpenseFilterValues,
} from "../components/ExpenseFilters";

const expenseStates = [
  "draft",
  "submitted",
  "approved",
  "rejected",
  "reimbursed",
];

function stateName(state: number | null) {
  return state === null ? "Unknown" : (expenseStates[state] ?? "Unknown");
}

export function ManagerPage({ onLogout }: { onLogout: () => void }) {
  const [section, setSection] = useState<"expenses" | "members" | "reviews">(
    "expenses",
  );
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [members, setMembers] = useState<ManagerMember[]>([]);
  const [reviews, setReviews] = useState<ManagerReviewExpense[]>([]);
  const [expensePage, setExpensePage] = useState({
    page: 1,
    total_pages: 1,
    total_count: 0,
    per_page: 5,
  });
  const [memberPage, setMemberPage] = useState({ page: 1, total_pages: 1 });
  const [reviewPage, setReviewPage] = useState({ page: 1, total_pages: 1 });
  const [editing, setEditing] = useState<Expense | null>(null);
  const [details, setDetails] = useState<ExpenseDetails | null>(null);
  const [reviewDetails, setReviewDetails] =
    useState<ManagerReviewDetails | null>(null);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [formKey, setFormKey] = useState(0);
  const [expenseFilters, setExpenseFilters] = useState<ExpenseFilterValues>({
    status: "",
    category: "",
    from_date: "",
    to_date: "",
    sort: "date",
    direction: "desc",
  });

  function showError(reason: Error) {
    setError(reason.message);
  }

  function loadExpenses(page = 1) {
    getManagerExpenses(page, expenseFilters)
      .then((result) => {
        setExpenses(result.expenses);
        setExpensePage(result.pagination);
      })
      .catch(showError);
  }

  function loadMembers(page = 1) {
    getManagerMembers(page)
      .then((result) => {
        setMembers(result.users);
        setMemberPage(result.pagination);
      })
      .catch(showError);
  }

  function loadReviews(page = 1) {
    getManagerReviews(page)
      .then((result) => {
        setReviews(result.expenses);
        setReviewPage(result.pagination);
      })
      .catch(showError);
  }

  useEffect(() => {
    if (section === "expenses") {
      Promise.all([getCategories(), getManagerExpenses(1, expenseFilters)])
        .then(([loadedCategories, expenseResult]) => {
          setCategories(loadedCategories);
          setExpenses(expenseResult.expenses);
          setExpensePage(expenseResult.pagination);
        })
        .catch(showError);
    }
    if (section === "members") loadMembers();
    if (section === "reviews") loadReviews();
  }, [section, expenseFilters]); // eslint-disable-line react-hooks/exhaustive-deps

  async function saveExpense(input: ExpenseInput) {
    setSaving(true);
    try {
      const saved = editing
        ? await updateManagerExpense(editing.id, input)
        : await createManagerExpense(input);
      setEditing(null);
      if (!editing) setFormKey((current) => current + 1);
      setExpenses((current) =>
        editing
          ? current.map((item) => (item.id === saved.id ? saved : item))
          : [saved, ...current],
      );
    } catch (reason) {
      showError(
        reason instanceof Error ? reason : new Error("Unable to save expense."),
      );
    } finally {
      setSaving(false);
    }
  }

  async function removeExpense(expense: Expense) {
    if (!window.confirm(`Delete "${expense.title}"?`)) return;
    try {
      await deleteManagerExpense(expense.id);
      loadExpenses(expensePage.page);
    } catch (reason) {
      showError(
        reason instanceof Error
          ? reason
          : new Error("Unable to delete expense."),
      );
    }
  }

  async function submitExpense(expense: Expense) {
    try {
      await submitManagerExpense(expense.id);
      loadExpenses(expensePage.page);
      loadReviews(reviewPage.page);
    } catch (reason) {
      showError(
        reason instanceof Error
          ? reason
          : new Error("Unable to submit expense."),
      );
    }
  }

  async function reopenExpense(expense: Expense) {
    try {
      await reopenManagerExpense(expense.id);
      loadExpenses(expensePage.page);
    } catch (reason) {
      showError(
        reason instanceof Error
          ? reason
          : new Error("Unable to reopen expense."),
      );
    }
  }

  async function review(
    expense: ManagerReviewExpense,
    action: "approve" | "reject",
  ) {
    const comment = window.prompt(
      action === "reject"
        ? "Reason for rejection (required)"
        : "Comment (optional)",
      "",
    );
    if (action === "reject" && !comment) return;
    try {
      if (action === "approve") {
          const updatedExpense = await approveManagerExpense(expense.id, comment ?? "");
          setReviews((current) => current.map((item) => item.id === updatedExpense.id ? updatedExpense : item));
        } else {
          await rejectManagerExpense(expense.id, comment ?? "");
        }
      loadReviews(reviewPage.page);
    } catch (reason) {
      showError(
        reason instanceof Error
          ? reason
          : new Error("Unable to update expense."),
      );
    }
  }

  return (
    <main className="dashboard">
      <nav className="dashboard-nav">
        <div className="brand">
          <span className="brand-mark">+</span>expenseflow{" "}
          <span className="admin-label">Manager</span>
        </div>
        <div className="header-actions">
          <NotificationButton />
          <ProfileButton />
          <button className="logout-button" onClick={onLogout}>
            Sign out
          </button>
        </div>
      </nav>
      <section className="employee-content">
        <div className="employee-intro">
          <p className="eyebrow">Manager workspace</p>
        </div>
        {error && <p className="error-message">{error}</p>}
        <nav className="admin-tabs" aria-label="Manager sections">
          <button
            className={
              section === "expenses" ? "admin-tab active" : "admin-tab"
            }
            onClick={() => setSection("expenses")}
          >
            My expenses
          </button>
          <button
            className={section === "members" ? "admin-tab active" : "admin-tab"}
            onClick={() => setSection("members")}
          >
            Team members
          </button>
          <button
            className={section === "reviews" ? "admin-tab active" : "admin-tab"}
            onClick={() => setSection("reviews")}
          >
            Review expenses
          </button>
        </nav>
        <div className="manager-panel">
          {section === "expenses" && (
            <ExpenseFilters
              categories={categories}
              value={expenseFilters}
              onChange={(value) => {
                setExpenseFilters(value);
                setExpensePage((current) => ({ ...current, page: 1 }));
              }}
            />
          )}
          {section === "expenses" && (
            <div className="manager-grid-single">
              <ExpenseForm
                key={`${editing?.id ?? "new"}-${formKey}`}
                categories={categories}
                expense={editing}
                isSaving={saving}
                error={null}
                onSubmit={saveExpense}
                onCancel={() => setEditing(null)}
              />
              <ExpenseList
                expenses={expenses}
                onEdit={setEditing}
                onDelete={removeExpense}
                onSubmit={submitExpense}
                onReopen={reopenExpense}
                onDetails={(expense) =>
                  getManagerExpense(expense.id)
                    .then(setDetails)
                    .catch(showError)
                }
                pagination={expensePage}
                onPageChange={loadExpenses}
              />
              {details && (
                <div className="detail-drawer">
                  <div className="panel-title">
                    <h3>{details.title}</h3>
                    <button
                      className="text-button"
                      onClick={() => setDetails(null)}
                    >
                      Close
                    </button>
                  </div>
                  <p>{details.description || "No description."}</p>
                  <p className="muted">
                    {details.state} · ${details.amount}
                  </p>
                  {details.payment_reference && (
                    <p className="payment-reference">
                      <strong>Payment reference:</strong>{" "}
                      {details.payment_reference}
                    </p>
                  )}
                  <h4>History</h4>
                  {details.history.length === 0 ? (
                    <p className="empty-state">No status history yet.</p>
                  ) : (
                    details.history.map((entry) => (
                      <div className="history-row" key={entry.id}>
                        <strong>{stateName(entry.prev_state)}</strong> To{" "}
                        <strong>{stateName(entry.next_state)}</strong> ,{" "}
                        <span>
                          {entry.changed_by ?? "System"} ·{" "}
                          {new Date(entry.created_at).toLocaleString()}
                        </span>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>
          )}
          {section === "members" && (
            <section className="manager-section">
              <div className="section-heading">
                <div>
                  <p className="eyebrow">Your team</p>
                  <h2>Team members</h2>
                </div>
              </div>
              <AdminTable headers={["Email", "Status"]}>
                {members.map((member) => (
                  <tr key={member.id}>
                    <td>{member.email}</td>
                    <td>
                      <span className="state">
                        {member.active ? "Active" : "Inactive"}
                      </span>
                    </td>
                  </tr>
                ))}
              </AdminTable>
              <AdminPagination
                page={memberPage.page}
                totalPages={memberPage.total_pages}
                onChange={loadMembers}
              />
            </section>
          )}
          {section === "reviews" && (
            <section className="manager-section">
              <div className="section-heading">
                <div>
                  <p className="eyebrow">Review queue</p>
                  <h2>Team expenses</h2>
                </div>
              </div>
              <AdminTable
                headers={["Expense", "Owner", "Amount", "State", "Actions"]}
              >
                {reviews.map((expense) => (
                  <tr key={expense.id}>
                    <td>
                      {expense.title}
                      <small>{expense.category_name}</small>
                    </td>
                    <td>{expense.user_email}</td>
                    <td>${expense.amount}</td>
                    <td>
                      <span className={`state state-${expense.state}`}>
                        {expense.state}
                      </span>
                      {expense.approval_stage === "awaiting_admin" && (
                        <small>Waiting for admin approval</small>
                      )}
                    </td>
                    <td>
                      <button
                        className="table-button"
                        onClick={() =>
                          getManagerReview(expense.id)
                            .then(setReviewDetails)
                            .catch(showError)
                        }
                      >
                        Details
                      </button>
                      {expense.state === "submitted" &&
                        expense.approval_stage !== "awaiting_admin" && (
                        <>
                          <button
                            className="table-button"
                            onClick={() => review(expense, "approve")}
                          >
                            Approve
                          </button>
                          <button
                            className="table-button danger-button"
                            onClick={() => review(expense, "reject")}
                          >
                            Reject
                          </button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </AdminTable>
              <AdminPagination
                page={reviewPage.page}
                totalPages={reviewPage.total_pages}
                onChange={loadReviews}
              />
              {reviewDetails && (
                <div className="detail-drawer">
                  <div className="panel-title">
                    <h3>{reviewDetails.title}</h3>
                    <button
                      className="text-button"
                      onClick={() => setReviewDetails(null)}
                    >
                      Close
                    </button>
                  </div>
                  <p>{reviewDetails.description || "No description."}</p>
                  <p className="muted">
                    {reviewDetails.user_email} · {reviewDetails.spent_date} · $
                    {reviewDetails.amount} · {reviewDetails.state}
                  </p>
                  {reviewDetails.payment_reference && (
                    <p className="payment-reference">
                      <strong>Payment reference:</strong>{" "}
                      {reviewDetails.payment_reference}
                    </p>
                  )}
                  <h4>History</h4>
                  {reviewDetails.history.length === 0 ? (
                    <p className="empty-state">No status history yet.</p>
                  ) : (
                    reviewDetails.history.map((entry) => (
                      <div className="history-row" key={entry.id}>
                        <strong>
                          {entry.prev_state === null
                            ? "Unknown"
                            : [
                                "draft",
                                "submitted",
                                "approved",
                                "rejected",
                                "reimbursed",
                              ][entry.prev_state]}
                        </strong>{" "}
                        To{" "}
                        <strong>
                          {entry.next_state === null
                            ? "Unknown"
                            : [
                                "draft",
                                "submitted",
                                "approved",
                                "rejected",
                                "reimbursed",
                              ][entry.next_state]}
                        </strong>{" "}
                        ,{" "}
                        <span>
                          {entry.changed_by ?? "System"} ·{" "}
                          {new Date(entry.created_at).toLocaleString()}
                        </span>
                      </div>
                    ))
                  )}
                </div>
              )}
            </section>
          )}
        </div>
      </section>
    </main>
  );
}
