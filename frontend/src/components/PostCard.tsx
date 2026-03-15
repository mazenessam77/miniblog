import { Calendar, Pencil, Trash2, User } from "lucide-react";
import { useNavigate } from "react-router-dom";

interface Post {
  id: number;
  title: string;
  content: string;
  author_id: number;
  author_username: string;
  created_at: string;
  updated_at: string;
}

interface Props {
  post: Post;
  currentUserId?: number;
  onDelete?: (id: number) => void;
}

export default function PostCard({ post, currentUserId, onDelete }: Props) {
  const navigate = useNavigate();
  const isOwner = currentUserId === post.author_id;
  const date = new Date(post.created_at).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });

  return (
    <article className="post-card">
      <h2>{post.title}</h2>
      <div className="post-meta">
        <span className="post-meta-item">
          <User size={13} />
          {post.author_username}
        </span>
        <span className="post-meta-sep">&middot;</span>
        <span className="post-meta-item">
          <Calendar size={13} />
          {date}
        </span>
      </div>
      <div className="post-content">{post.content}</div>
      {isOwner && (
        <div className="post-actions">
          <button className="btn-edit" onClick={() => navigate(`/edit/${post.id}`)}>
            <Pencil size={14} />
            Edit
          </button>
          <button className="btn-delete" onClick={() => onDelete?.(post.id)}>
            <Trash2 size={14} />
            Delete
          </button>
        </div>
      )}
    </article>
  );
}
