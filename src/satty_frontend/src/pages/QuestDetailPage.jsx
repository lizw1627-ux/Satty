import React from 'react';
import { useParams } from 'react-router-dom';

const QuestDetailPage = () => {
  const { id } = useParams();
  return (
    <div>
      <h1>Quest Details</h1>
      <p>Quest ID: {id}</p>
      {/* Quest details and submission form will go here */}
    </div>
  );
};

export default QuestDetailPage;