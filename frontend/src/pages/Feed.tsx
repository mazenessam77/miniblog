import { Loader2, Rss } from "lucide-react";
import { useEffect, useState } from "react";
import PostCard from "../components/PostCard";
import { useAuth } from "../hooks/useAuth";
import api from "../services/api";

interface Post {
  id: number;
  title: string;
  content: string;
  author_id: number;
  author_username: string;
  created_at: string;
  updated_at: string;
}

export default function Feed() {
  const { user } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get("/posts")
      .then((res) => setPosts(res.data))
      .catch(() => setError("Could not load posts. Check your connection."))
      .finally(() => setLoading(false));
  }, []);

  if (loading)
    return (
      <div className="loading-state">
        <Loader2 size={30} className="spin" />
        <span>Loading posts…</span>
      </div>
    );

  if (error) return <p className="error" style={{ margin: 20 }}>{error}</p>;

  return (
    <div>
      <div className="feed-page-header">
        <h1>Home</h1>
      </div>

      {posts.length === 0 ? (
        <div className="empty-state">
          <Rss size={52} className="empty-state-icon" />
          <h3>Nothing here yet</h3>
          <p>Be the first to write something for the world to read.</p>
        </div>
      ) : (
        posts.map((post) => (
          <PostCard
            key={post.id}
            post={post}
            currentUserId={user?.id}
            onDelete={async (id) => {
              if (!confirm("Delete this post?")) return;
              await api.delete(`/posts/${id}`);
              setPosts((prev) => prev.filter((p) => p.id !== id));
            }}
          />
        ))
      )}
    </div>
  );
}
