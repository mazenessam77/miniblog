import { Image, Loader2, X } from "lucide-react";
import { FormEvent, useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import api from "../services/api";

const AVATAR_COLORS = [
  "#1d9bf0", "#794bc4", "#00ba7c", "#ff7a00", "#e0245e", "#17bf63",
];

function avatarColor(username: string) {
  const hash = username.split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

const MAX_CONTENT = 2000;

export default function EditPost() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // Image state
  const [imageKey, setImageKey] = useState<string | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const navigate = useNavigate();

  useEffect(() => {
    api
      .get(`/posts/${id}`)
      .then((res) => {
        setTitle(res.data.title);
        setContent(res.data.content);
        if (res.data.image_url) {
          setImagePreview(res.data.image_url);
          // Reconstruct key from URL pattern
          const parts = res.data.image_url.split("/resized/medium/");
          if (parts[1]) setImageKey(`uploads/${parts[1]}`);
        }
      })
      .catch(() => setError("Post not found"))
      .finally(() => setLoading(false));
  }, [id]);

  const handleImageSelect = async (file: File) => {
    if (!file.type.startsWith("image/")) return;
    setUploading(true);
    setError("");
    try {
      const { data } = await api.post("/media/presigned-url", {
        filename: file.name,
        content_type: file.type,
      });
      await fetch(data.upload_url, {
        method: "PUT",
        body: file,
        headers: { "Content-Type": file.type },
      });
      setImageKey(data.key);
      setImagePreview(URL.createObjectURL(file));
    } catch {
      setError("Image upload failed. Please try again.");
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (uploading) return;
    setError("");
    setSaving(true);
    try {
      await api.put(`/posts/${id}`, { title, content, image_key: imageKey });
      navigate("/dashboard");
    } catch (err: any) {
      setError(err.response?.data?.detail || "Failed to update post");
    } finally {
      setSaving(false);
    }
  };

  const remaining = MAX_CONTENT - content.length;
  const color = user ? avatarColor(user.username) : "#1d9bf0";

  if (loading)
    return (
      <div className="loading-state">
        <Loader2 size={30} className="spin" />
        <span>Loading post…</span>
      </div>
    );

  return (
    <div>
      <div className="feed-page-header">
        <h1>Edit Post</h1>
      </div>

      {error && <p className="error" style={{ margin: "16px 20px 0" }}>{error}</p>}

      <form onSubmit={handleSubmit}>
        <div className="compose-box">
          <div className="compose-avatar" style={{ background: color }}>
            {user?.username[0].toUpperCase()}
          </div>

          <div className="compose-form">
            <input
              className="compose-title"
              type="text"
              placeholder="Post title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              maxLength={200}
            />

            <textarea
              className="compose-body"
              placeholder="What's on your mind?"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              required
              maxLength={MAX_CONTENT}
            />

            {uploading && (
              <div className="upload-progress">
                <Loader2 size={16} className="spin" />
                Uploading image…
              </div>
            )}

            {imagePreview && !uploading ? (
              <div className="upload-preview">
                <img src={imagePreview} alt="Preview" />
                <button
                  type="button"
                  className="upload-remove"
                  onClick={() => {
                    setImageKey(null);
                    setImagePreview(null);
                  }}
                >
                  <X size={14} />
                </button>
              </div>
            ) : !uploading ? (
              <div
                className="upload-area"
                onClick={() => fileRef.current?.click()}
              >
                <Image size={20} style={{ margin: "0 auto 6px" }} />
                {imageKey ? "Change photo" : "Add a photo (optional)"}
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/*"
                  style={{ display: "none" }}
                  onChange={(e) => {
                    const f = e.target.files?.[0];
                    if (f) handleImageSelect(f);
                  }}
                />
              </div>
            ) : null}

            <div className="compose-footer">
              <span
                className={`compose-char-count ${
                  remaining < 50 ? (remaining < 0 ? "limit" : "warn") : ""
                }`}
              >
                {remaining} characters left
              </span>
              <button
                type="submit"
                className="btn"
                disabled={saving || uploading || !title.trim() || !content.trim()}
              >
                {saving && <span className="btn-spinner" />}
                {saving ? "Saving…" : "Save changes"}
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
