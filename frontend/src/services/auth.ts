import { api } from './api';

export type UserRole = 'TRAVELER' | 'BUDDY';

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  avatar?: string;
  location?: string;
  age?: number;
  nationality?: string;
  languages?: string[];
  description?: string;
  interests?: string[];
  verificationStatus?: 'verified' | 'pending' | 'unverified';
}

export interface AuthResponse {
  user: User;
  token: string;
}

export const authService = {
  login: async (email: string, password: string): Promise<AuthResponse> => {
    const trimmedEmail = email.trim();
    const response = await api.get<User[]>('/users', {
      params: { email: trimmedEmail }
    });
    
    const user = response.data.find(u => 
      u.email.toLowerCase() === trimmedEmail.toLowerCase() && 
      (u as any).password === password
    );

    if (user) {
      // In a real app, we'd get a JWT token. Here we simulate it.
      const token = btoa(JSON.stringify(user));
      return { user, token };
    }
    
    throw new Error('Invalid email or password');
  },

  register: async (userData: Omit<User, 'id'> & { password: string }): Promise<AuthResponse> => {
    // Check if user exists
    const existing = await api.get('/users', { params: { email: userData.email } });
    if (existing.data.length > 0) {
      throw new Error('Email already exists');
    }

    const response = await api.post('/users', {
      ...userData,
      id: Math.random().toString(36).substr(2, 9)
    });

    const user = response.data;

    // If registering as a BUDDY, create a basic entry in the buddies collection
    if (user.role === 'BUDDY') {
      await api.post('/buddies', {
        id: user.id,
        name: user.name,
        location: 'Vietnam',
        rating: 5.0,
        reviewCount: 0,
        languages: ['VIETNAMESE', 'ENGLISH'],
        description: 'New Local Buddy joined our community!',
        image: '/img/default-buddy.jpg',
        tags: ['New Member'],
        price: 15,
        availability: 'Available'
      });
    }

    const token = btoa(JSON.stringify(user));
    return { user, token };
  },

  getCurrentUser: (): User | null => {
    const token = localStorage.getItem('token');
    const userStr = localStorage.getItem('user');
    if (token && userStr) {
      return JSON.parse(userStr);
    }
    return null;
  },

  updateProfile: async (id: string, userData: Partial<User>): Promise<User> => {
    const response = await api.patch(`/users/${id}`, userData);
    return response.data;
  }
};
