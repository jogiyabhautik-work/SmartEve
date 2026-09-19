export type UserRole = "organizer" | "anchor";

export interface User {
  uid: string;
  name: string;
  email: string;
  role: UserRole;
  createdAt: number;
}
