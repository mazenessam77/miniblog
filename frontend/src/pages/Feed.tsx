import { Loader2, Rss } from "lucide-react";
import { useEffect, useState } from "react";
import PostCard from "../components/PostCard";
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
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get("/posts")
      .then((res) => setPosts(res.data))
      .catch(() => setError("Failed to load posts. Check your connection and try again."))
      .finally(() => setLoading(false));
  }, []);

  if (loading)
    return (
      <div className="loading-state">
        <Loader2 size={32} className="spin" />
        <p>Loading posts…</p>
      </div>
    );

  if (error) return <p className="error">{error}</p>;

  return (
    <div>
      <div className="feed-header">
        <Rss size={22} />
        <h1 className="feed-title">Recent Posts</h1>
      </div>
      {posts.length === 0 ? (
        <div className="empty-state">
          <Rss size={48} className="empty-icon" />
          <p>No posts yet. Be the first to write something!</p>
        </div>
      ) : (
        posts.map((post) => <PostCard key={post.id} post={post} />)
      )}
    </div>
  );
}
