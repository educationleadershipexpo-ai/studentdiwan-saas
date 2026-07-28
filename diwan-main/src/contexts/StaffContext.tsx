/* eslint-disable react-refresh/only-export-components */
import React, { createContext, useContext, useState, ReactNode, useEffect, useCallback, useMemo } from "react";
import { db, handleFirestoreError, OperationType, isFirestoreWorking } from "@/firebase";
import { collection, onSnapshot, query, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, where } from "firebase/firestore";
import { useAuth } from "@/hooks/useAuth";
import { smartDb } from "@/lib/localDb";
import { Staff } from "@/types";
import { userRepository } from "@/repositories/UserRepository";

interface StaffContextType {
  staff: Staff[];
  addStaff: (newStaff: Omit<Staff, "id" | "uid" | "createdAt">) => Promise<void>;
  updateStaff: (id: string, updatedStaff: Partial<Staff>) => Promise<void>;
  deleteStaff: (id: string) => Promise<void>;
  refetchStaff: () => Promise<void>;
  loading: boolean;
}

export const StaffContext = createContext<StaffContextType | undefined>(undefined);

export const StaffProvider = ({ children }: { children: ReactNode }) => {
  const { user } = useAuth();
  const [staff, setStaff] = useState<Staff[]>(() => {
    try {
      const cached = sessionStorage.getItem("sd_cache_staff");
      return cached ? JSON.parse(cached) : [];
    } catch {
      return [];
    }
  });
  const [loading, setLoading] = useState<boolean>(() => {
    try {
      const cached = sessionStorage.getItem("sd_cache_staff");
      return !cached || JSON.parse(cached).length === 0;
    } catch {
      return true;
    }
  });

  useEffect(() => {
    if (staff.length > 0) {
      try { sessionStorage.setItem("sd_cache_staff", JSON.stringify(staff)); } catch {}
    }
  }, [staff]);

  const fetchStaff = useCallback(async () => {
    if (!user) return;
    if (staff.length === 0) setLoading(true);
    try {
      const data = await smartDb.getAllLatest("Staff", undefined);
      if (data !== null) setStaff(data);
    } catch (error) {
      console.error("Error fetching staff:", error);
    } finally {
      setLoading(false);
    }
  }, [user, staff.length]);

  useEffect(() => {
    if (!user) {
      setStaff([]);
      setLoading(false);
      return;
    }

    if (staff.length === 0) setLoading(true);
    const unsubscribe = smartDb.watch("Staff", undefined, (data) => {
      if (data && Array.isArray(data) && data.length > 0) {
        setStaff(data as Staff[]);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user, staff.length]);

  // No seed function — cPanel MySQL is the single source of truth (61+ real
  // staff records). The old auto-seed-on-empty here used to inject 4 fake
  // mock employees into the real database every time a differently-uid'd
  // admin loaded this page and (because of the uid-scoping bug above) saw
  // zero staff — compounding the visibility bug with actual data pollution.

  const addStaff = useCallback(async (newStaff: Omit<Staff, "id" | "uid" | "createdAt">) => {
    if (!user) return;
    try {
      await smartDb.create("Staff", {
        ...newStaff,
        uid: user.uid,
        createdAt: new Date().toISOString()
      });
      if (!isFirestoreWorking) fetchStaff();
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, "Staff");
    }
  }, [user, fetchStaff]);

  const updateStaff = useCallback(async (id: string, updatedStaff: Partial<Staff>) => {
    try {
      await smartDb.update("Staff", id, { ...updatedStaff, updatedAt: new Date().toISOString() });
      if (!isFirestoreWorking) fetchStaff();
      // Real login deactivation — previously Staff.status and the real
      // login account (provisioned by staffAccounts.ts on onboarding/hire)
      // were fully disconnected, so a staff member set Inactive/Terminated
      // here kept a fully working login indefinitely. Mirrors the status
      // onto their real User row; login itself enforces it server-side
      // (POST /api/session/login). Symmetric: setting status back to
      // Active reactivates the login too, so a correction isn't permanent.
      if (updatedStaff.status === "Inactive" || updatedStaff.status === "Terminated" || updatedStaff.status === "Active") {
        const email = updatedStaff.email || staff.find(s => s.id === id)?.email;
        if (email) {
          userRepository.findByEmail(email).then(existingUser => {
            if (!existingUser) return;
            return userRepository.update(existingUser.id, { status: updatedStaff.status === "Active" ? "Active" : "Inactive" });
          }).catch(() => {});
        }
      }
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, "Staff");
    }
  }, [fetchStaff, staff]);

  const deleteStaff = useCallback(async (id: string) => {
    try {
      await smartDb.delete("Staff", id);
      if (!isFirestoreWorking) fetchStaff();
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, "Staff");
    }
  }, [fetchStaff]);

  const value = useMemo(() => ({ staff, addStaff, updateStaff, deleteStaff, refetchStaff: fetchStaff, loading }),
    [staff, addStaff, updateStaff, deleteStaff, fetchStaff, loading]);

  return (
    <StaffContext.Provider value={value}>
      {children}
    </StaffContext.Provider>
  );
};

export const useStaff = () => {
  const context = useContext(StaffContext);
  if (context === undefined) {
    throw new Error("useStaff must be used within a StaffProvider");
  }
  return context;
};
