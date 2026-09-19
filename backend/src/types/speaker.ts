export type SpeakerArrivalStatus = "expected" | "arrived" | "absent";

export interface Speaker {
  id: string;
  name: string;
  designation: string;
  organization: string;
  topic: string;
  bio: string;
  highlights: string[];
  photoUrl?: string;
  status: SpeakerArrivalStatus;
}
