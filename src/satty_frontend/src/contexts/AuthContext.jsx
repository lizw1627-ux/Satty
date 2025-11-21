import React, { createContext, useContext, useState, useEffect } from 'react';
import { AuthClient } from '@dfinity/auth-client';
import { HttpAgent } from '@dfinity/agent';
import { canisterId, createActor } from '../../../../declarations/satty_backend';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authClient, setAuthClient] = useState(null);
  const [actor, setActor] = useState(null);
  const [principal, setPrincipal] = useState(null);

  useEffect(() => {
    AuthClient.create().then(async (client) => {
      setAuthClient(client);
      const isAuthenticated = await client.isAuthenticated();
      if (isAuthenticated) {
        handleAuthenticated(client);
      }
    });
  }, []);

  const login = async () => {
    return new Promise(async (resolve, reject) => {
      try {
        await authClient.login({
          identityProvider: `http://localhost:4943?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`,
          onSuccess: () => {
            handleAuthenticated(authClient);
            resolve();
          },
          onError: reject,
        });
      } catch (error) {
        reject(error);
      }
    });
  };

  const handleAuthenticated = (client) => {
    const identity = client.getIdentity();
    setPrincipal(identity.getPrincipal());
    const agent = new HttpAgent({ identity });
    const actor = createActor(canisterId, { agent });
    setActor(actor);
    setIsAuthenticated(true);
  };

  const logout = async () => {
    await authClient.logout();
    setIsAuthenticated(false);
    setActor(null);
    setPrincipal(null);
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, login, logout, actor, principal }}>
      {children}
    </AuthContext.Provider>
  );
};
