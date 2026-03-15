import { Pencil, Trash2 } from "lucide-react";
import { useNavigate } from "react-router-dom";

interface Post {
  id: number;
  title: string;
  content: string;
  author_id: number;
  author_username: string;
  image_url?: string | null;
  author_avatar_url?: string | null;
  created_at: string;
  updated_at: string;
}

interface Props {
  post: Post;
  currentUserId?: number;
  onDelete?: (id: number) => void;
}

const AVATAR_COLORS = [
  "#1d9bf0",
  "#794bc4",
  "#00ba7c",
  "#ff7a00",
  "#e0245e",
  "#17bf63",
];

function avatarColor(username: string) {
  const hash = username
    .split("")
    .reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

function timeAgo(dateStr: string): string {
  const diff = (Date.now() - new Date(dateStr).getTime()) / 1000;
  if (diff < 60) return `${Math.floor(diff)}s`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d`;
  return new Date(dateStr).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

export default function PostCard({ post, currentUserId, onDelete }: Props) {
  const navigate = useNavigate();
  const isOwner = currentUserId === post.author_id;
  const color = avatarColor(post.author_username);

  return (
    <article className="post-card">
      <div className="post-avatar" style={post.author_avatar_url ? {} : { background: color }}>
        {post.author_avatar_url
          ? <img src={post.author_avatar_url} alt={post.author_username} className="post-avatar-img" onError={(e) => { e.currentTarget.style.display = "none"; }} />
          : post.author_username[0].toUpperCase()
        }
      </div>

      <div className="post-body">
        <div className="post-header">
          <span className="post-author">{post.author_username}</span>
          <span className="post-handle">@{post.author_username.toLowerCase()}</span>
          <span className="post-dot">&middot;</span>
          <span className="post-time">{timeAgo(post.created_at)}</span>
        </div>

        <div className="post-title">{post.title}</div>
        <div className="post-content-text">{post.content}</div>

        {post.image_url && (
          <img
            src={post.image_url}
            alt="Post image"
            className="post-image"
            onError={(e) => {
              e.currentTarget.style.display = "none";
            }}
          />
        )}

        {isOwner && (
          <div className="post-actions">
            <button
              className="btn-edit"
              onClick={() => navigate(`/edit/${post.id}`)}
            >
              <Pencil size={13} />
              Edit
            </button>
            <button
              className="btn-delete"
              onClick={() => onDelete?.(post.id)}
            >
              <Trash2 size={13} />
              Delete
            </button>
          </div>
        )}
      </div>
    </article>
  );
}
