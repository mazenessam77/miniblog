import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
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

export default function Dashboard() {
  const { user } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get("/posts")
      .then((res) => {
        setPosts(res.data.filter((p: Post) => p.author_id === user?.id));
      })
      .catch(() => setError("Failed to load posts. Please try again."))
      .finally(() => setLoading(false));
  }, [user]);

  const handleDelete = async (id: number) => {
    if (!confirm("Delete this post?")) return;
    try {
      await api.delete(`/posts/${id}`);
      setPosts((prev) => prev.filter((p) => p.id !== id));
    } catch (err: any) {
      alert(err.response?.data?.detail || "Failed to delete post");
    }
  };

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="error">{error}</p>;

  return (
    <div>
      <div className="page-header">
        <h1>My Posts</h1>
        <Link to="/create" className="btn">
          New Post
        </Link>
      </div>
      {posts.length === 0 ? (
        <p>
          You haven't written any posts yet.{" "}
          <Link to="/create">Create your first post</Link>
        </p>
      ) : (
        posts.map((post) => (
          <PostCard
            key={post.id}
            post={post}
            currentUserId={user?.id}
            onDelete={handleDelete}
          />
        ))
      )}
    </div>
  );
}
