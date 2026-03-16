import axios from 'axios';

const API_BASE_URL = 'http://localhost:3000';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface Review {
  id: number;
  author: string;
  date: string;
  content: string;
  rating: number;
  avatar: string;
}

export interface Buddy {
  id: string;
  name: string;
  age: number;
  location: string;
  rating: number;
  reviewCount: number;
  languages: string[];
  description: string;
  image: string;
  tags: string[];
  price: number;
  availability: string;
  interests?: string[];
  reviews?: Review[];
  phone?: string;
  idCardFront?: string;
  idCardBack?: string;
  verificationStatus?: 'verified' | 'pending' | 'unverified';
}

export const buddyService = {
  getAll: async () => {
    const response = await api.get<Buddy[]>('/buddies');
    return response.data;
  },
  getById: async (id: string) => {
    const response = await api.get<Buddy>(`/buddies/${id}`);
    return response.data;
  },
  updateProfile: async (id: string, data: Partial<Buddy>) => {
    const response = await api.patch<Buddy>(`/buddies/${id}`, data);
    return response.data;
  },
};

export const bookingService = {
  getAll: async () => {
    const response = await api.get('/bookings');
    return response.data;
  },
  getById: async (id: string) => {
    const response = await api.get(`/bookings/${id}`);
    return response.data;
  },
  create: async (bookingData: any) => {
    const response = await api.post('/bookings', bookingData);
    return response.data;
  },
  getByUserId: async (userId: string) => {
    const response = await api.get(`/bookings?userId=${userId}`);
    return response.data;
  },
  getByBuddyId: async (buddyId: string) => {
    const response = await api.get(`/bookings?buddyId=${buddyId}`);
    return response.data;
  },
  updateStatus: async (id: string, status: string) => {
    const response = await api.patch(`/bookings/${id}`, { status });
    return response.data;
  },
  updateMeetupStatus: async (id: string, status: string | null) => {
    const response = await api.patch(`/bookings/${id}`, { meetupStatus: status });
    return response.data;
  },
};

export const matchService = {
  getAll: async () => {
    const response = await api.get('/matches');
    return response.data;
  },
};

export const earningService = {
  getStats: async () => {
    const response = await api.get('/earnings');
    return response.data;
  },
};

export const transactionService = {
  getAll: async () => {
    const response = await api.get('/earnings');
    return response.data.transactions;
  },
  getByBuddyId: async (buddyId: string) => {
    const response = await api.get('/earnings');
    // In a real scenario, this would be filtered by the backend
    return response.data.transactions.filter((t: any) => String(t.buddyId) === String(buddyId));
  },
};

export const messageService = {
  getConversations: async () => {
    const response = await api.get('/conversations');
    return response.data;
  },
  getMessagesByConvId: async (convId: string) => {
    const response = await api.get(`/conversations/${convId}`);
    return response.data.messages;
  },
  sendMessage: async (convId: string, message: any) => {
    const response = await api.get(`/conversations/${convId}`);
    const conversation = response.data;
    const updatedMessages = [...conversation.messages, { ...message, id: Date.now() }];
    const patchResponse = await api.patch(`/conversations/${convId}`, {
      messages: updatedMessages,
      lastMsg: message.text || message.content,
      time: 'Just now'
    });
    return patchResponse.data;
  },
};

export const requestService = {
  getPending: async () => {
    const response = await api.get('/requests?status=pending');
    return response.data;
  },
  updateStatus: async (id: string, status: string) => {
    const response = await api.patch(`/requests/${id}`, { status });
    return response.data;
  },
};

export interface Experience {
  id: string;
  title: string;
  travelerName: string;
  travelerAvatar?: string;
  image: string;
  location: string;
  date: string;
  tags: string[];
  storyContent: string;
  buddyId: string;
  buddyName: string;
  rating?: number;
  pinned?: boolean;
}

export const experienceService = {
  getAll: async () => {
    const response = await api.get<Experience[]>('/experiences');
    return response.data;
  },
  getById: async (id: string) => {
    const response = await api.get<Experience>(`/experiences/${id}`);
    return response.data;
  },
  getByBuddyId: async (buddyId: string) => {
    const response = await api.get<Experience[]>(`/experiences?buddyId=${buddyId}`);
    return response.data;
  },
  update: async (id: string, data: Partial<Experience>) => {
    const response = await api.patch<Experience>(`/experiences/${id}`, data);
    return response.data;
  },
  create: async (data: Omit<Experience, 'id'>) => {
    const response = await api.post<Experience>('/experiences', { ...data, id: Date.now().toString() });
    return response.data;
  },
};

export const notificationService = {
  getAll: async () => {
    const response = await api.get('/notifications');
    return response.data;
  },
  markAsRead: async (id: string) => {
    const response = await api.patch(`/notifications/${id}`, { unread: false });
    return response.data;
  },
};
