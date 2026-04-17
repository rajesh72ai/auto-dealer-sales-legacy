const CHAT_URL = '/api/chat';
const PROVIDERS_URL = '/api/chat/providers';

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ChatApiResponse {
  reply: string;
  model: string;
}

export interface ProviderInfo {
  key: string;
  label: string;
  model: string;
}

export interface ProvidersResponse {
  providers: ProviderInfo[];
  defaultProvider: string;
}

export async function getProviders(token: string | null): Promise<ProvidersResponse> {
  const response = await fetch(PROVIDERS_URL, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  if (!response.ok) return { providers: [], defaultProvider: 'gemini' };
  return response.json();
}

export async function sendChatMessage(
  messages: ChatMessage[],
  provider: string,
  signal?: AbortSignal,
): Promise<ChatApiResponse> {
  const token = sessionStorage.getItem('autosales_token');

  const response = await fetch(CHAT_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ messages, provider }),
    signal,
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(
      `Chat error ${response.status}: ${text || response.statusText}`,
    );
  }

  return response.json();
}
