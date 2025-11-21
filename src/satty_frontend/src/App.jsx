import { useState } from 'react';
import { satty_backend } from 'declarations/satty_backend';

import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import HomePage from './pages/HomePage';
import LeaderboardPage from './pages/LeaderboardPage';
import ProfilePage from './pages/ProfilePage';
import QuestDetailPage from './pages/QuestDetailPage';

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<HomePage />} />
        <Route path="leaderboard" element={<LeaderboardPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="quest/:id" element={<QuestDetailPage />} />
      </Route>
    </Routes>
  );
}

export default App;

export default App;
