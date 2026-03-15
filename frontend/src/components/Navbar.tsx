import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export default function Navbar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  return (
    <nav>
      <div className="nav-content">
        <Link to="/" className="logo">
          MiniBlog
        </Link>
        <div className="nav-links">
          <Link to="/">Feed</Link>
          {user ? (
            <>
              <Link to="/dashboard">My Posts</Link>
              <Link to="/create">New Post</Link>
              <span className="nav-user">{user.username}</span>
              <button onClick={handleLogout}>Logout</button>
            </>
          ) : (
            <>
              <Link to="/login">Login</Link>
              <Link to="/register">Register</Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
}
