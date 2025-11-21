// It's not possible to directly import Motoko types in JavaScript.
// These are JavaScript representations of the Motoko types in your common/types.mo file.
// You should keep these in sync with your Motoko types.

export const Quest = {
  id: '',
  title: '',
  description: '',
  startTime: 0,
  endTime: 0,
  reward: 0,
  participants: [],
};

export const UserProfile = {
  id: '',
  principal: '',
  username: '',
  twitter: '',
  submissions: [],
};

export const QuestSubmission = {
  questId: '',
  userId: '',
  submissionText: '',
  timestamp: 0,
};

export const Winner = {
  questId: '',
  userId: '',
  amount: 0,
};
