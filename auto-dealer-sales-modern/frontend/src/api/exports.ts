import apiClient from './axios';

/**
 * Download a CSV export by type and dealer code.
 * Creates a temporary Blob URL link and triggers browser download.
 */
export async function downloadExport(type: string, dealerCode: string) {
  const response = await apiClient.get(`/export/${type}`, {
    params: { dealerCode },
    responseType: 'blob',
  });

  const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;

  // Extract filename from Content-Disposition header or build default
  const disposition = response.headers['content-disposition'];
  let filename = `${type}-${dealerCode}.csv`;
  if (disposition) {
    const match = disposition.match(/filename="?([^";\n]+)"?/);
    if (match?.[1]) {
      filename = match[1];
    }
  }

  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
}
