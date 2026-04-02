import { createContext, useContext, useState, useCallback } from 'react';
import { CheckCircle, XCircle, AlertTriangle, X } from 'lucide-react';

type ToastType = 'success' | 'error' | 'warning';

interface Toast {
  id: number;
  type: ToastType;
  message: string;
}

interface ToastContextValue {
  addToast: (type: ToastType, message: string) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

let nextId = 0;

const toastConfig: Record<ToastType, { bg: string; icon: React.ReactNode }> = {
  success: {
    bg: 'bg-emerald-50 border-emerald-200 text-emerald-800',
    icon: <CheckCircle className="h-5 w-5 text-emerald-500" />,
  },
  error: {
    bg: 'bg-red-50 border-red-200 text-red-800',
    icon: <XCircle className="h-5 w-5 text-red-500" />,
  },
  warning: {
    bg: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    icon: <AlertTriangle className="h-5 w-5 text-yellow-500" />,
  },
};

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const removeToast = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const addToast = useCallback(
    (type: ToastType, message: string) => {
      const id = ++nextId;
      setToasts((prev) => [...prev, { id, type, message }]);
      setTimeout(() => removeToast(id), 4000);
    },
    [removeToast],
  );

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      {/* Toast container */}
      <div className="fixed right-4 top-4 z-[100] flex flex-col gap-2">
        {toasts.map((toast) => {
          const config = toastConfig[toast.type];
          return (
            <div
              key={toast.id}
              className={`flex w-80 items-start gap-3 rounded-lg border px-4 py-3 shadow-lg animate-in slide-in-from-right duration-300 ${config.bg}`}
            >
              <div className="flex-shrink-0 pt-0.5">{config.icon}</div>
              <p className="flex-1 text-sm font-medium">{toast.message}</p>
              <button
                onClick={() => removeToast(toast.id)}
                className="flex-shrink-0 rounded p-0.5 opacity-60 transition-opacity hover:opacity-100"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
}
