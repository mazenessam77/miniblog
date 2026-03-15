import { createContext, ReactNode, useContext, useState } from "react";
import api from "../services/api";

interface User {
  id: number;
  username: string;
  email: string;
  avatar_url?: string;
}

interface AuthContextType {
  user: User | null;
  login: (username: string, password: string) => Promise<void>;
  register: (
    username: string,
    email: string,
    password: string
  ) => Promise<void>;
  logout: () => void;
  updateAvatar: (avatarUrl: string) => void;
}

const AuthContext = createContext<AuthContextType>(null!);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(() => {
    const stored = localStorage.getItem("user");
    return stored ? JSON.parse(stored) : null;
  });

  const saveAuth = (accessToken: string, userData: User) => {
    localStorage.setItem("token", accessToken);
    localStorage.setItem("user", JSON.stringify(userData));
    api.defaults.headers.common["Authorization"] = `Bearer ${accessToken}`;
    setUser(userData);
  };

  const login = async (username: string, password: string) => {
    const res = await api.post("/auth/login", { username, password });
    saveAuth(res.data.access_token, res.data.user);
  };

  const register = async (
    username: string,
    email: string,
    password: string
  ) => {
    const res = await api.post("/auth/register", {
      username,
      email,
      password,
    });
    saveAuth(res.data.access_token, res.data.user);
  };

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    delete api.defaults.headers.common["Authorization"];
    setUser(null);
  };

  const updateAvatar = (avatarUrl: string) => {
    if (!user) return;
    const updated = { ...user, avatar_url: avatarUrl };
    localStorage.setItem("user", JSON.stringify(updated));
    setUser(updated);
  };

  return (
    <AuthContext.Provider value={{ user, login, register, logout, updateAvatar }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
