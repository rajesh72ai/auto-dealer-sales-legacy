import { useState, useEffect, useCallback } from 'react';
import { Plus, Users, KeyRound, Lock, Unlock } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import { getUsers, createUser, updateUser, resetPassword, lockUser, unlockUser } from '@/api/users';
import type { SystemUserInfo, CreateUserRequest, UpdateUserRequest } from '@/types/user';

const USER_TYPES = [
  { value: 'A', label: 'Admin' },
  { value: 'M', label: 'Manager' },
  { value: 'S', label: 'Sales' },
  { value: 'F', label: 'Finance' },
  { value: 'C', label: 'Clerk' },
];

const ACTIVE_OPTIONS = [
  { value: 'Y', label: 'Active' },
  { value: 'N', label: 'Inactive' },
];

const TYPE_BADGE_COLORS: Record<string, { bg: string; text: string }> = {
  A: { bg: 'bg-purple-50', text: 'text-purple-700' },
  M: { bg: 'bg-blue-50', text: 'text-blue-700' },
  S: { bg: 'bg-emerald-50', text: 'text-emerald-700' },
  F: { bg: 'bg-amber-50', text: 'text-amber-700' },
  C: { bg: 'bg-gray-100', text: 'text-gray-600' },
};

const TYPE_LABELS: Record<string, string> = {
  A: 'Admin',
  M: 'Manager',
  S: 'Sales',
  F: 'Finance',
  C: 'Clerk',
};

function TypeBadge({ type }: { type: string }) {
  const colors = TYPE_BADGE_COLORS[type] || TYPE_BADGE_COLORS.C;
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${colors.bg} ${colors.text}`}>
      {TYPE_LABELS[type] || type}
    </span>
  );
}

function FlagBadge({ value, yesLabel, noLabel }: { value: string; yesLabel: string; noLabel: string }) {
  const isYes = value === 'Y';
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${
        isYes ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'
      }`}
    >
      <span className={`h-1.5 w-1.5 rounded-full ${isYes ? 'bg-emerald-500' : 'bg-red-500'}`} />
      {isYes ? yesLabel : noLabel}
    </span>
  );
}

const defaultCreateForm: CreateUserRequest = {
  userId: '',
  userName: '',
  password: '',
  userType: 'S',
  dealerCode: '',
  activeFlag: 'Y',
};

const defaultEditForm: UpdateUserRequest = {
  userName: '',
  userType: 'S',
  dealerCode: '',
  activeFlag: 'Y',
};

function UserManagementPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<SystemUserInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);

  // Create modal
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState<CreateUserRequest>({ ...defaultCreateForm });
  const [createErrors, setCreateErrors] = useState<Record<string, string>>({});

  // Edit modal
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<SystemUserInfo | null>(null);
  const [editForm, setEditForm] = useState<UpdateUserRequest>({ ...defaultEditForm });
  const [editErrors, setEditErrors] = useState<Record<string, string>>({});

  // Reset password modal
  const [isResetOpen, setIsResetOpen] = useState(false);
  const [resetUserId, setResetUserId] = useState('');
  const [newPassword, setNewPassword] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getUsers({ page, size: 20 });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [page, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validateCreate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!createForm.userId.trim()) errs.userId = 'User ID is required';
    if (!createForm.userName.trim()) errs.userName = 'Name is required';
    if (!createForm.password.trim()) errs.password = 'Password is required';
    if (createForm.password.length < 6) errs.password = 'Password must be at least 6 characters';
    if (!createForm.dealerCode.trim()) errs.dealerCode = 'Dealer code is required';
    setCreateErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const validateEdit = (): boolean => {
    const errs: Record<string, string> = {};
    if (!editForm.userName.trim()) errs.userName = 'Name is required';
    if (!editForm.dealerCode.trim()) errs.dealerCode = 'Dealer code is required';
    setEditErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateCreate()) return;
    try {
      await createUser(createForm);
      addToast('success', 'User created successfully');
      setIsCreateOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to create user');
    }
  };

  const handleEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateEdit() || !editingUser) return;
    try {
      await updateUser(editingUser.userId, editForm);
      addToast('success', 'User updated successfully');
      setIsEditOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to update user');
    }
  };

  const handleResetPassword = async () => {
    if (!newPassword.trim() || newPassword.length < 6) {
      addToast('error', 'Password must be at least 6 characters');
      return;
    }
    try {
      await resetPassword(resetUserId, newPassword);
      addToast('success', 'Password reset successfully');
      setIsResetOpen(false);
      setNewPassword('');
    } catch {
      addToast('error', 'Failed to reset password');
    }
  };

  const handleLockToggle = async (user: SystemUserInfo) => {
    try {
      if (user.lockedFlag === 'Y') {
        await unlockUser(user.userId);
        addToast('success', `User ${user.userId} unlocked`);
      } else {
        await lockUser(user.userId);
        addToast('success', `User ${user.userId} locked`);
      }
      fetchData();
    } catch {
      addToast('error', 'Failed to change lock status');
    }
  };

  const openCreate = () => {
    setCreateForm({ ...defaultCreateForm });
    setCreateErrors({});
    setIsCreateOpen(true);
  };

  const openEdit = (user: SystemUserInfo) => {
    setEditingUser(user);
    setEditForm({
      userName: user.userName,
      userType: user.userType,
      dealerCode: user.dealerCode,
      activeFlag: user.activeFlag,
    });
    setEditErrors({});
    setIsEditOpen(true);
  };

  const openReset = (userId: string) => {
    setResetUserId(userId);
    setNewPassword('');
    setIsResetOpen(true);
  };

  const handleCreateChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setCreateForm((prev) => ({ ...prev, [name]: value }));
    if (createErrors[name]) setCreateErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const handleEditChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setEditForm((prev) => ({ ...prev, [name]: value }));
    if (editErrors[name]) setEditErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const columns: Column<SystemUserInfo>[] = [
    { key: 'userId', header: 'User ID', sortable: true },
    { key: 'userName', header: 'Name', sortable: true },
    {
      key: 'userType',
      header: 'Type',
      render: (row) => <TypeBadge type={row.userType} />,
    },
    { key: 'dealerCode', header: 'Dealer', sortable: true },
    {
      key: 'activeFlag',
      header: 'Active',
      render: (row) => <FlagBadge value={row.activeFlag} yesLabel="Active" noLabel="Inactive" />,
    },
    {
      key: 'lockedFlag',
      header: 'Locked',
      render: (row) => <FlagBadge value={row.lockedFlag === 'Y' ? 'N' : 'Y'} yesLabel="Unlocked" noLabel="Locked" />,
    },
    {
      key: 'lastLoginTs',
      header: 'Last Login',
      render: (row) =>
        row.lastLoginTs ? (
          <span className="text-gray-600 text-xs">{new Date(row.lastLoginTs).toLocaleString()}</span>
        ) : (
          <span className="text-gray-400 text-xs">Never</span>
        ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
          <button
            onClick={() => openReset(row.userId)}
            title="Reset Password"
            className="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
          >
            <KeyRound className="h-4 w-4" />
          </button>
          <button
            onClick={() => handleLockToggle(row)}
            title={row.lockedFlag === 'Y' ? 'Unlock' : 'Lock'}
            className="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
          >
            {row.lockedFlag === 'Y' ? <Unlock className="h-4 w-4" /> : <Lock className="h-4 w-4" />}
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50">
              <Users className="h-5 w-5 text-purple-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
              <p className="mt-0.5 text-sm text-gray-500">Manage system user accounts, roles, and access</p>
            </div>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-purple-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500/20"
        >
          <Plus className="h-4 w-4" />
          Create User
        </button>
      </div>

      {/* Table */}
      <DataTable
        columns={columns}
        data={items}
        loading={loading}
        page={page}
        totalPages={totalPages}
        totalElements={totalElements}
        onPageChange={setPage}
        onRowClick={(row) => openEdit(row)}
      />

      {/* Create User Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Create User"
        size="lg"
      >
        <form onSubmit={handleCreate} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="User ID"
              name="userId"
              value={createForm.userId}
              onChange={handleCreateChange}
              error={createErrors.userId}
              required
              placeholder="e.g. jsmith01"
            />
            <FormField
              label="User Name"
              name="userName"
              value={createForm.userName}
              onChange={handleCreateChange}
              error={createErrors.userName}
              required
              placeholder="John Smith"
            />
          </div>
          <FormField
            label="Password"
            name="password"
            value={createForm.password}
            onChange={handleCreateChange}
            error={createErrors.password}
            required
            placeholder="Minimum 6 characters"
          />
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="User Type"
              name="userType"
              type="select"
              value={createForm.userType}
              onChange={handleCreateChange}
              options={USER_TYPES}
            />
            <FormField
              label="Dealer Code"
              name="dealerCode"
              value={createForm.dealerCode}
              onChange={handleCreateChange}
              error={createErrors.dealerCode}
              required
              placeholder="DLR01"
            />
            <FormField
              label="Status"
              name="activeFlag"
              type="select"
              value={createForm.activeFlag}
              onChange={handleCreateChange}
              options={ACTIVE_OPTIONS}
            />
          </div>
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsCreateOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-purple-700"
            >
              Create User
            </button>
          </div>
        </form>
      </Modal>

      {/* Edit User Modal */}
      <Modal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title={editingUser ? `Edit User: ${editingUser.userId}` : 'Edit User'}
        size="lg"
      >
        <form onSubmit={handleEdit} className="space-y-4">
          <FormField
            label="User Name"
            name="userName"
            value={editForm.userName}
            onChange={handleEditChange}
            error={editErrors.userName}
            required
          />
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="User Type"
              name="userType"
              type="select"
              value={editForm.userType}
              onChange={handleEditChange}
              options={USER_TYPES}
            />
            <FormField
              label="Dealer Code"
              name="dealerCode"
              value={editForm.dealerCode}
              onChange={handleEditChange}
              error={editErrors.dealerCode}
              required
            />
            <FormField
              label="Status"
              name="activeFlag"
              type="select"
              value={editForm.activeFlag}
              onChange={handleEditChange}
              options={ACTIVE_OPTIONS}
            />
          </div>
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsEditOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-purple-700"
            >
              Update User
            </button>
          </div>
        </form>
      </Modal>

      {/* Reset Password Modal */}
      <Modal
        isOpen={isResetOpen}
        onClose={() => setIsResetOpen(false)}
        title={`Reset Password: ${resetUserId}`}
        size="md"
      >
        <div className="space-y-4">
          <p className="text-sm text-gray-600">
            Enter a new password for user <span className="font-semibold">{resetUserId}</span>.
          </p>
          <FormField
            label="New Password"
            name="newPassword"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            required
            placeholder="Minimum 6 characters"
          />
          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsResetOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              onClick={handleResetPassword}
              className="rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-amber-700"
            >
              Reset Password
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

export default UserManagementPage;
