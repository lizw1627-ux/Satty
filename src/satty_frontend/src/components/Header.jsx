import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Header = () => {
  const { isAuthenticated, login, logout, principal } = useAuth();

  return (
    <header className="header">
      <div className="container">
        <Link to="/" className="logo">Satty</Link>
        <nav>
          <Link to="/">Home</Link>
          <Link to="/leaderboard">Leaderboard</Link>
          {isAuthenticated && <Link to="/profile">Profile</Link>}
        </nav>
        <div>
          {isAuthenticated ? (
            <>
              <span className="principal-id">{principal?.toText().slice(0, 5)}...</span>
              <button onClick={logout} className="btn btn-secondary">Logout</button>
            </>
          ) : (
            <button onClick={login} className="btn btn-primary">Login</button>
          )}
        </div>
      </div>
    </header>
  );
};

export default Header;