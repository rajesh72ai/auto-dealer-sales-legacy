import { useState, useEffect, useCallback } from 'react';
import {
  getBatchJobs,
  getCheckpoints,
  executeCheckpointAction,
  runDailyBatch,
  runMonthlyBatch,
  runWeeklyBatch,
  runPurgeBatch,
  runValidationBatch,
  runGlPostingBatch,
  runCrmExtract,
  runDmsExtract,
  runDataLakeExtract,
} from '@/api/batch';
import type { BatchJob, BatchRunResult, Checkpoint } from '@/types/batch';

const STATUS_STYLES: Record<string, string> = {
  OK: 'bg-green-100 text-green-800',
  ER: 'bg-red-100 text-red-800',
  RN: 'bg-blue-100 text-blue-800',
  AB: 'bg-red-200 text-red-900',
  NR: 'bg-gray-100 text-gray-600',
};

export default function BatchJobsPage() {
  const [jobs, setJobs] = useState<BatchJob[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedJob, setSelectedJob] = useState<string | null>(null);
  const [checkpoints, setCheckpoints] = useState<Checkpoint[]>([]);
  const [runResult, setRunResult] = useState<BatchRunResult | null>(null);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState('');

  const fetchJobs = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getBatchJobs();
      setJobs(data);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load batch jobs');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  const handleViewCheckpoints = async (programId: string) => {
    setSelectedJob(programId);
    try {
      const data = await getCheckpoints(programId);
      setCheckpoints(data);
    } catch {
      setCheckpoints([]);
    }
  };

  const handleCheckpointAction = async (
    programId: string,
    action: 'DISP' | 'RESET' | 'COMPL',
  ) => {
    try {
      await executeCheckpointAction({ programId, action });
      handleViewCheckpoints(programId);
      fetchJobs();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Checkpoint action failed');
    }
  };

  const handleRunJob = async (
    programId: string,
    runFn: () => Promise<BatchRunResult>,
  ) => {
    setRunning(true);
    setRunResult(null);
    setError('');
    try {
      const result = await runFn();
      setRunResult(result);
      fetchJobs();
    } catch (err: any) {
      setError(err.response?.data?.message || `Failed to run ${programId}`);
    } finally {
      setRunning(false);
    }
  };

  const jobRunFunctions: Record<string, () => Promise<BatchRunResult>> = {
    BATDLY00: runDailyBatch,
    BATMTH00: runMonthlyBatch,
    BATWKL00: runWeeklyBatch,
    BATPUR00: runPurgeBatch,
    BATVAL00: runValidationBatch,
    BATGLINT: runGlPostingBatch,
    BATCRM00: () => runCrmExtract() as any,
    BATDMS00: () => runDmsExtract() as any,
    BATDLAKE: () => runDataLakeExtract() as any,
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Batch Job Management</h1>
        <button
          onClick={fetchJobs}
          className="px-4 py-2 text-sm bg-gray-100 hover:bg-gray-200 rounded-lg transition"
        >
          Refresh
        </button>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-lg text-sm">
          {error}
          <button onClick={() => setError('')} className="ml-2 font-bold">x</button>
        </div>
      )}

      {/* Job List */}
      <div className="bg-white shadow rounded-lg overflow-hidden mb-6">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Program</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Last Run</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Records</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-500">Loading...</td></tr>
            ) : jobs.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">No batch jobs configured</td></tr>
            ) : (
              jobs.map((job) => (
                <tr key={job.programId} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm font-mono font-medium text-gray-900">
                    {job.programId}
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-700">{job.programName}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">{job.lastRunDate || 'Never'}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">
                    {job.recordsProcessed.toLocaleString()}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex px-2 py-0.5 text-xs font-semibold rounded-full ${STATUS_STYLES[job.runStatus] || 'bg-gray-100'}`}>
                      {job.statusDescription}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm space-x-2">
                    {jobRunFunctions[job.programId] && (
                      <button
                        onClick={() => handleRunJob(job.programId, jobRunFunctions[job.programId])}
                        disabled={running}
                        className="px-3 py-1 text-xs bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50 transition"
                      >
                        {running ? 'Running...' : 'Run'}
                      </button>
                    )}
                    <button
                      onClick={() => handleViewCheckpoints(job.programId)}
                      className="px-3 py-1 text-xs bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition"
                    >
                      Checkpoints
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Run Result */}
      {runResult && (
        <div className="bg-white shadow rounded-lg p-5 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-3">
            Run Result: {runResult.programId}
          </h2>
          <div className="grid grid-cols-4 gap-4 mb-4">
            <div className="bg-green-50 p-3 rounded-lg">
              <div className="text-xs text-green-600 font-medium">Status</div>
              <div className="text-lg font-bold text-green-800">{runResult.status}</div>
            </div>
            <div className="bg-blue-50 p-3 rounded-lg">
              <div className="text-xs text-blue-600 font-medium">Processed</div>
              <div className="text-lg font-bold text-blue-800">
                {runResult.recordsProcessed.toLocaleString()}
              </div>
            </div>
            <div className="bg-red-50 p-3 rounded-lg">
              <div className="text-xs text-red-600 font-medium">Errors</div>
              <div className="text-lg font-bold text-red-800">{runResult.recordsError}</div>
            </div>
            <div className="bg-gray-50 p-3 rounded-lg">
              <div className="text-xs text-gray-600 font-medium">Duration</div>
              <div className="text-sm font-medium text-gray-800">
                {runResult.startedAt?.substring(11, 19)} - {runResult.completedAt?.substring(11, 19)}
              </div>
            </div>
          </div>
          <div className="space-y-1">
            <h3 className="text-sm font-medium text-gray-700">Phases:</h3>
            {runResult.phases.map((phase, i) => (
              <div key={i} className="text-sm text-gray-600 pl-4">{phase}</div>
            ))}
          </div>
          {runResult.warnings.length > 0 && (
            <div className="mt-3 space-y-1">
              <h3 className="text-sm font-medium text-amber-700">Warnings:</h3>
              {runResult.warnings.map((w, i) => (
                <div key={i} className="text-sm text-amber-600 pl-4">{w}</div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Checkpoints Panel */}
      {selectedJob && (
        <div className="bg-white shadow rounded-lg p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Checkpoints: {selectedJob}
            </h2>
            <div className="space-x-2">
              <button
                onClick={() => handleCheckpointAction(selectedJob, 'DISP')}
                className="px-3 py-1 text-xs bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition"
              >
                Display
              </button>
              <button
                onClick={() => handleCheckpointAction(selectedJob, 'RESET')}
                className="px-3 py-1 text-xs bg-amber-100 text-amber-700 rounded hover:bg-amber-200 transition"
              >
                Reset
              </button>
              <button
                onClick={() => handleCheckpointAction(selectedJob, 'COMPL')}
                className="px-3 py-1 text-xs bg-green-100 text-green-700 rounded hover:bg-green-200 transition"
              >
                Complete
              </button>
              <button
                onClick={() => setSelectedJob(null)}
                className="px-3 py-1 text-xs bg-gray-200 text-gray-600 rounded hover:bg-gray-300 transition"
              >
                Close
              </button>
            </div>
          </div>
          {checkpoints.length === 0 ? (
            <p className="text-sm text-gray-400">No checkpoints found for this program.</p>
          ) : (
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Seq</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Timestamp</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Last Key</th>
                  <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">In</th>
                  <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Out</th>
                  <th className="px-3 py-2 text-right text-xs font-medium text-gray-500">Error</th>
                  <th className="px-3 py-2 text-left text-xs font-medium text-gray-500">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {checkpoints.map((cp, i) => (
                  <tr key={i}>
                    <td className="px-3 py-2 font-mono">{cp.checkpointSeq}</td>
                    <td className="px-3 py-2">{cp.checkpointTimestamp?.substring(0, 19)}</td>
                    <td className="px-3 py-2 font-mono">{cp.lastKeyValue || '-'}</td>
                    <td className="px-3 py-2 text-right">{cp.recordsIn?.toLocaleString()}</td>
                    <td className="px-3 py-2 text-right">{cp.recordsOut?.toLocaleString()}</td>
                    <td className="px-3 py-2 text-right">{cp.recordsError?.toLocaleString()}</td>
                    <td className="px-3 py-2">
                      <span className={`inline-flex px-2 py-0.5 text-xs rounded-full ${
                        cp.checkpointStatus === 'CP' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
                      }`}>
                        {cp.checkpointStatus}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}
