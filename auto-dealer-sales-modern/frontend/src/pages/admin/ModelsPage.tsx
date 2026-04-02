import { useState, useEffect, useCallback } from 'react';
import { Plus, Car } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import DataTable from '@/components/shared/DataTable';
import type { Column } from '@/components/shared/DataTable';
import Modal from '@/components/shared/Modal';
import FormField from '@/components/shared/FormField';
import StatusBadge from '@/components/shared/StatusBadge';
import { getModels, createModel, updateModel } from '@/api/models';
import type { ModelMaster, ModelMasterRequest } from '@/types/admin';

const MAKES = [
  { value: 'FRD', label: 'Ford' },
  { value: 'TYT', label: 'Toyota' },
  { value: 'HND', label: 'Honda' },
  { value: 'CHV', label: 'Chevrolet' },
  { value: 'BMW', label: 'BMW' },
];

const BODY_STYLES = [
  { value: 'SD', label: 'Sedan' },
  { value: 'SV', label: 'SUV' },
  { value: 'TK', label: 'Truck' },
  { value: 'CP', label: 'Coupe' },
  { value: 'HB', label: 'Hatchback' },
  { value: 'VN', label: 'Van' },
  { value: 'CV', label: 'Convertible' },
];

const ENGINE_TYPES = [
  { value: 'GAS', label: 'Gasoline' },
  { value: 'DSL', label: 'Diesel' },
  { value: 'HYB', label: 'Hybrid' },
  { value: 'EV', label: 'Electric' },
];

const TRANSMISSIONS = [
  { value: 'A', label: 'Automatic' },
  { value: 'M', label: 'Manual' },
  { value: 'C', label: 'CVT' },
];

const DRIVE_TRAINS = [
  { value: 'FWD', label: 'Front-Wheel Drive' },
  { value: 'RWD', label: 'Rear-Wheel Drive' },
  { value: 'AWD', label: 'All-Wheel Drive' },
  { value: '4WD', label: '4-Wheel Drive' },
];

const currentYear = new Date().getFullYear();
const YEARS = Array.from({ length: 5 }, (_, i) => ({
  value: String(currentYear + 1 - i),
  label: String(currentYear + 1 - i),
}));

const ACTIVE_OPTIONS = [
  { value: 'Y', label: 'Active' },
  { value: 'N', label: 'Inactive' },
];

const defaultForm: ModelMasterRequest = {
  modelYear: currentYear,
  makeCode: '',
  modelCode: '',
  modelName: '',
  bodyStyle: '',
  trimLevel: '',
  engineType: '',
  transmission: '',
  driveTrain: '',
  exteriorColors: null,
  interiorColors: null,
  curbWeight: null,
  fuelEconomyCity: null,
  fuelEconomyHwy: null,
  activeFlag: 'Y',
};

function bodyStyleLabel(code: string): string {
  return BODY_STYLES.find((b) => b.value === code)?.label ?? code;
}

function engineLabel(code: string): string {
  return ENGINE_TYPES.find((e) => e.value === code)?.label ?? code;
}

function transLabel(code: string): string {
  return TRANSMISSIONS.find((t) => t.value === code)?.label ?? code;
}

function driveLabel(code: string): string {
  return DRIVE_TRAINS.find((d) => d.value === code)?.label ?? code;
}

function makeLabel(code: string): string {
  return MAKES.find((m) => m.value === code)?.label ?? code;
}

function ModelsPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<ModelMaster[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState<ModelMaster | null>(null);
  const [form, setForm] = useState<ModelMasterRequest>({ ...defaultForm });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [makeFilter, setMakeFilter] = useState('');
  const [yearFilter, setYearFilter] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getModels({
        page,
        size: 20,
        make: makeFilter || undefined,
        year: yearFilter ? Number(yearFilter) : undefined,
      });
      setItems(result.content);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch {
      addToast('error', 'Failed to load vehicle models');
    } finally {
      setLoading(false);
    }
  }, [page, makeFilter, yearFilter, addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!form.makeCode) errs.makeCode = 'Make is required';
    if (!form.modelCode.trim()) errs.modelCode = 'Model code is required';
    if (!form.modelName.trim()) errs.modelName = 'Model name is required';
    if (!form.bodyStyle) errs.bodyStyle = 'Body style is required';
    if (!form.engineType) errs.engineType = 'Engine type is required';
    if (!form.transmission) errs.transmission = 'Transmission is required';
    if (!form.driveTrain) errs.driveTrain = 'Drive train is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    try {
      if (editing) {
        await updateModel(editing.modelYear, editing.makeCode, editing.modelCode, form);
        addToast('success', 'Model updated successfully');
      } else {
        await createModel(form);
        addToast('success', 'Model created successfully');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Operation failed');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: ['modelYear', 'curbWeight', 'fuelEconomyCity', 'fuelEconomyHwy'].includes(name)
        ? (value === '' ? null : Number(value))
        : value,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ ...defaultForm });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (item: ModelMaster) => {
    setEditing(item);
    setForm({
      modelYear: item.modelYear,
      makeCode: item.makeCode,
      modelCode: item.modelCode,
      modelName: item.modelName,
      bodyStyle: item.bodyStyle,
      trimLevel: item.trimLevel,
      engineType: item.engineType,
      transmission: item.transmission,
      driveTrain: item.driveTrain,
      exteriorColors: item.exteriorColors,
      interiorColors: item.interiorColors,
      curbWeight: item.curbWeight,
      fuelEconomyCity: item.fuelEconomyCity,
      fuelEconomyHwy: item.fuelEconomyHwy,
      activeFlag: item.activeFlag,
    });
    setErrors({});
    setIsModalOpen(true);
  };

  const columns: Column<ModelMaster>[] = [
    { key: 'modelYear', header: 'Year', sortable: true },
    {
      key: 'makeCode',
      header: 'Make',
      sortable: true,
      render: (row) => (
        <span className="inline-flex items-center rounded-md bg-gray-100 px-2 py-0.5 text-xs font-semibold text-gray-700">
          {makeLabel(row.makeCode)}
        </span>
      ),
    },
    { key: 'modelCode', header: 'Code' },
    {
      key: 'modelName',
      header: 'Name',
      sortable: true,
      render: (row) => <span className="font-medium text-gray-900">{row.modelName}</span>,
    },
    {
      key: 'bodyStyle',
      header: 'Body',
      render: (row) => bodyStyleLabel(row.bodyStyle),
    },
    {
      key: 'engineType',
      header: 'Engine',
      render: (row) => engineLabel(row.engineType),
    },
    {
      key: 'transmission',
      header: 'Trans',
      render: (row) => transLabel(row.transmission),
    },
    {
      key: 'driveTrain',
      header: 'Drive',
      render: (row) => driveLabel(row.driveTrain),
    },
    {
      key: 'activeFlag',
      header: 'Status',
      render: (row) => <StatusBadge status={row.activeFlag === 'Y' ? 'active' : 'inactive'} />,
    },
  ];

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50">
            <Car className="h-5 w-5 text-purple-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Vehicle Models</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage make, model, and configuration master data</p>
          </div>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
        >
          <Plus className="h-4 w-4" />
          Add Model
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <select
          value={makeFilter}
          onChange={(e) => { setMakeFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Makes</option>
          {MAKES.map((m) => (
            <option key={m.value} value={m.value}>{m.label}</option>
          ))}
        </select>
        <select
          value={yearFilter}
          onChange={(e) => { setYearFilter(e.target.value); setPage(0); }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
        >
          <option value="">All Years</option>
          {YEARS.map((y) => (
            <option key={y.value} value={y.value}>{y.label}</option>
          ))}
        </select>
        {(makeFilter || yearFilter) && (
          <button
            onClick={() => { setMakeFilter(''); setYearFilter(''); setPage(0); }}
            className="text-sm font-medium text-brand-600 transition-colors hover:text-brand-700"
          >
            Clear filters
          </button>
        )}
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

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editing ? 'Edit Vehicle Model' : 'New Vehicle Model'}
        size="xl"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Model Year"
              name="modelYear"
              type="select"
              value={form.modelYear}
              onChange={handleChange}
              required
              options={YEARS}
              disabled={!!editing}
            />
            <FormField
              label="Make"
              name="makeCode"
              type="select"
              value={form.makeCode}
              onChange={handleChange}
              error={errors.makeCode}
              required
              options={MAKES}
              disabled={!!editing}
            />
            <FormField
              label="Model Code"
              name="modelCode"
              value={form.modelCode}
              onChange={handleChange}
              error={errors.modelCode}
              required
              placeholder="CAM"
              disabled={!!editing}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Model Name"
              name="modelName"
              value={form.modelName}
              onChange={handleChange}
              error={errors.modelName}
              required
              placeholder="Camry LE"
            />
            <FormField
              label="Trim Level"
              name="trimLevel"
              value={form.trimLevel}
              onChange={handleChange}
              placeholder="LE, SE, XLE..."
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Body Style"
              name="bodyStyle"
              type="select"
              value={form.bodyStyle}
              onChange={handleChange}
              error={errors.bodyStyle}
              required
              options={BODY_STYLES}
            />
            <FormField
              label="Engine Type"
              name="engineType"
              type="select"
              value={form.engineType}
              onChange={handleChange}
              error={errors.engineType}
              required
              options={ENGINE_TYPES}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <FormField
              label="Transmission"
              name="transmission"
              type="select"
              value={form.transmission}
              onChange={handleChange}
              error={errors.transmission}
              required
              options={TRANSMISSIONS}
            />
            <FormField
              label="Drive Train"
              name="driveTrain"
              type="select"
              value={form.driveTrain}
              onChange={handleChange}
              error={errors.driveTrain}
              required
              options={DRIVE_TRAINS}
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <FormField
              label="Curb Weight (lbs)"
              name="curbWeight"
              type="number"
              value={form.curbWeight ?? ''}
              onChange={handleChange}
              placeholder="3400"
            />
            <FormField
              label="MPG City"
              name="fuelEconomyCity"
              type="number"
              value={form.fuelEconomyCity ?? ''}
              onChange={handleChange}
              placeholder="28"
            />
            <FormField
              label="MPG Highway"
              name="fuelEconomyHwy"
              type="number"
              value={form.fuelEconomyHwy ?? ''}
              onChange={handleChange}
              placeholder="39"
            />
          </div>
          <FormField
            label="Status"
            name="activeFlag"
            type="select"
            value={form.activeFlag}
            onChange={handleChange}
            options={ACTIVE_OPTIONS}
          />

          <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
            >
              {editing ? 'Update Model' : 'Create Model'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default ModelsPage;
