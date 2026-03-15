import { Camera, Loader2 } from "lucide-react";
import { useRef, useState } from "react";
import { useAuth } from "../hooks/useAuth";
import api from "../services/api";

const AVATAR_COLORS = ["#1d9bf0","#794bc4","#00ba7c","#ff7a00","#e0245e","#17bf63"];
function avatarColor(username: string) {
  const hash = username.split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

export default function Profile() {
  const { user, updateAvatar } = useAuth();
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  if (!user) return null;
  const color = avatarColor(user.username);

  const handleAvatarSelect = async (file: File) => {
    if (!file.type.startsWith("image/")) return;
    setUploading(true);
    setError("");
    try {
      const { data } = await api.post("/media/presigned-url", {
        filename: file.name,
        content_type: file.type,
      });
      const uploadRes = await fetch(data.upload_url, {
        method: "PUT",
        body: file,
        headers: { "Content-Type": file.type },
      });
      if (!uploadRes.ok) throw new Error(`Upload failed: ${uploadRes.status}`);

      const res = await api.put("/users/me/avatar", { avatar_key: data.key });
      updateAvatar(res.data.avatar_url);
    } catch {
      setError("Failed to upload photo. Please try again.");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      <div className="feed-page-header">
        <h1>Profile</h1>
      </div>

      <div className="profile-card">
        <div className="profile-avatar-wrap">
          <div
            className="profile-avatar"
            style={user.avatar_url ? {} : { background: color }}
            onClick={() => !uploading && fileRef.current?.click()}
            title="Change photo"
          >
            {user.avatar_url ? (
              <img src={user.avatar_url} alt={user.username} className="profile-avatar-img" />
            ) : (
              user.username[0].toUpperCase()
            )}
            <div className="profile-avatar-overlay">
              {uploading ? <Loader2 size={22} className="spin" /> : <Camera size={22} />}
            </div>
          </div>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            style={{ display: "none" }}
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) handleAvatarSelect(f);
            }}
          />
        </div>

        {error && <p className="error" style={{ textAlign: "center", marginTop: 12 }}>{error}</p>}

        <div className="profile-info">
          <div className="profile-username">{user.username}</div>
          <div className="profile-handle">@{user.username.toLowerCase()}</div>
          <div className="profile-email">{user.email}</div>
        </div>
      </div>
    </div>
  );
}
