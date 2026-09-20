import { Pool } from "@neondatabase/serverless";
import dotenv from "dotenv";

dotenv.config();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function seedNeon() {
  console.log("🐘 Connecting to Neon.tech PostgreSQL...");

  // 1. Get existing Users
  const usersRes = await pool.query("SELECT id, email, role, full_name FROM users");
  const users = usersRes.rows;
  console.log("Existing users:", users);

  const organizer = users.find((u) => u.role === "organizer") || users[0];
  const anchors = users.filter((u) => u.role === "anchor");
  const primaryAnchor = anchors[0] || users[1] || organizer;
  const secondaryAnchor = anchors[1] || primaryAnchor;

  const organizerId = organizer.id;
  const anchorId1 = primaryAnchor.id;
  const anchorId2 = secondaryAnchor.id;

  // 2. Ensure live event
  const eventRes = await pool.query("SELECT id, title FROM events LIMIT 1");
  let liveEventId: string;
  const now = new Date();
  const startTime = new Date(now.getTime() - 15 * 60 * 1000);
  const endTime = new Date(now.getTime() + 4 * 60 * 60 * 1000);

  if (eventRes.rows.length > 0) {
    liveEventId = eventRes.rows[0].id;
    await pool.query(
      `UPDATE events SET 
        title = 'TechNova Live AI Summit 2026', 
        event_type = 'seminar',
        status = 'live',
        location = 'Main Auditorium & Stage A',
        description = 'International flagship conference on deterministic intelligence and autonomous edge systems.',
        max_attendees = 1200,
        start_date = $1,
        end_date = $2
      WHERE id = $3`,
      [startTime, endTime, liveEventId]
    );
    console.log("Updated live event:", liveEventId);
  } else {
    const inserted = await pool.query(
      `INSERT INTO events (title, event_type, status, location, description, max_attendees, created_by, start_date, end_date)
       VALUES ('TechNova Live AI Summit 2026', 'seminar', 'live', 'Main Auditorium & Stage A', 'International flagship conference on autonomous systems.', 1200, $1, $2, $3)
       RETURNING id`,
      [organizerId, startTime, endTime]
    );
    liveEventId = inserted.rows[0].id;
    console.log("Created live event:", liveEventId);
  }

  // 3. Ensure a completed event for anchor history
  const compRes = await pool.query("SELECT id FROM events WHERE status = 'completed' LIMIT 1");
  let completedEventId: string;
  if (compRes.rows.length > 0) {
    completedEventId = compRes.rows[0].id;
  } else {
    const compStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const compEnd = new Date(compStart.getTime() + 6 * 60 * 60 * 1000);
    const insertedComp = await pool.query(
      `INSERT INTO events (title, event_type, status, location, description, max_attendees, created_by, start_date, end_date)
       VALUES ('National Robotics Expo 2026', 'competition', 'completed', 'IIT Tech Arena', 'Robotics and autonomous systems showcase.', 820, $1, $2, $3)
       RETURNING id`,
      [organizerId, compStart, compEnd]
    );
    completedEventId = insertedComp.rows[0].id;
  }

  // 4. Ensure an upcoming invited event
  const invRes = await pool.query("SELECT id FROM events WHERE title = 'Smart City Hackathon Finals' LIMIT 1");
  let invitedEventId: string;
  if (invRes.rows.length > 0) {
    invitedEventId = invRes.rows[0].id;
  } else {
    const invStart = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const invEnd = new Date(invStart.getTime() + 5 * 60 * 60 * 1000);
    const insertedInv = await pool.query(
      `INSERT INTO events (title, event_type, status, location, description, max_attendees, created_by, start_date, end_date)
       VALUES ('Smart City Hackathon Finals', 'competition', 'scheduled', 'Innovation Hub Hall C', '36-hour hackathon finale pitches with 20 finalist teams.', 500, $1, $2, $3)
       RETURNING id`,
      [organizerId, invStart, invEnd]
    );
    invitedEventId = insertedInv.rows[0].id;
  }

  // 5. Link event_anchors for live, completed, and invited events
  await pool.query("DELETE FROM event_anchors WHERE anchor_id = $1 OR anchor_id = $2", [anchorId1, anchorId2]);

  // Active anchor assignment
  await pool.query(
    `INSERT INTO event_anchors (event_id, anchor_id, assigned_by, status, accepted_at, activated_at, notes)
     VALUES ($1, $2, $3, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'Primary live stage anchor')`,
    [liveEventId, anchorId1, organizerId]
  );
  if (anchorId2 !== anchorId1) {
    await pool.query(
      `INSERT INTO event_anchors (event_id, anchor_id, assigned_by, status, accepted_at, activated_at, notes)
       VALUES ($1, $2, $3, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'Co-anchor')`,
      [liveEventId, anchorId2, organizerId]
    );
  }

  // Completed event assignment
  await pool.query(
    `INSERT INTO event_anchors (event_id, anchor_id, assigned_by, status, accepted_at, completed_at, notes)
     VALUES ($1, $2, $3, 'completed', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'Successfully hosted with zero schedule drift')`,
    [completedEventId, anchorId1, organizerId]
  );

  // Invited event assignment
  await pool.query(
    `INSERT INTO event_anchors (event_id, anchor_id, assigned_by, status, invited_at, notes)
     VALUES ($1, $2, $3, 'invited', CURRENT_TIMESTAMP, 'Invitation for hackathon stage moderation')`,
    [invitedEventId, anchorId1, organizerId]
  );
  console.log("Linked event_anchors in Neon!");

  // 6. Ensure real Speaker (Bhautik Jogiya) linked to live event
  const spkRes = await pool.query("SELECT id FROM speakers WHERE name ILIKE '%Bhautik%' LIMIT 1");
  let speakerId: string;
  if (spkRes.rows.length > 0) {
    speakerId = spkRes.rows[0].id;
    await pool.query(
      `UPDATE speakers SET 
        event_id = $1, 
        name = 'Bhautik Jogiya',
        designation = 'Founder & Chief Architect',
        organization = 'BliXo Tech',
        bio = 'Pioneer in sub-millisecond edge intelligence and deterministic AI stage automation.',
        profile_image_url = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        order_in_event = 1
      WHERE id = $2`,
      [liveEventId, speakerId]
    );
  } else {
    const insertedSpk = await pool.query(
      `INSERT INTO speakers (event_id, name, designation, organization, bio, profile_image_url, order_in_event)
       VALUES ($1, 'Bhautik Jogiya', 'Founder & Chief Architect', 'BliXo Tech', 'Pioneer in edge systems.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', 1)
       RETURNING id`,
      [liveEventId]
    );
    speakerId = insertedSpk.rows[0].id;
  }
  console.log("Configured speaker:", speakerId);

  // 7. Seed agenda_items for live event
  await pool.query("DELETE FROM agenda_items WHERE event_id = $1", [liveEventId]);

  const item1Start = new Date(now.getTime() - 15 * 60 * 1000);
  const item1End = new Date(now.getTime());
  const item2Start = new Date(now.getTime());
  const item2End = new Date(now.getTime() + 25 * 60 * 1000);
  const item3Start = new Date(now.getTime() + 25 * 60 * 1000);
  const item3End = new Date(now.getTime() + 45 * 60 * 1000);
  const item4Start = new Date(now.getTime() + 45 * 60 * 1000);
  const item4End = new Date(now.getTime() + 60 * 60 * 1000);

  const a1 = await pool.query(
    `INSERT INTO agenda_items (event_id, title, description, type, order_in_agenda, duration_minutes, start_time, end_time, status, notes)
     VALUES ($1, 'Summit Opening & Housekeeping', 'Official welcoming remarks and stage housekeeping rules', 'opening', 1, 15, $2, $3, 'completed', 'Opening complete on time')
     RETURNING id`,
    [liveEventId, item1Start, item1End]
  );

  const a2 = await pool.query(
    `INSERT INTO agenda_items (event_id, title, description, type, speaker_id, order_in_agenda, duration_minutes, start_time, end_time, status, notes)
     VALUES ($1, 'Keynote: Autonomous Reasoning & Distributed Edge Systems', 'Deep-dive architectural presentation on fail-safe AI pipelines and real-time inference at hyperscale', 'speaker_session', $2, 2, 25, $3, $4, 'in_progress', 'Audience engagement high; 28 live questions incoming')
     RETURNING id`,
    [liveEventId, speakerId, item2Start, item2End]
  );

  const a3 = await pool.query(
    `INSERT INTO agenda_items (event_id, title, description, type, order_in_agenda, duration_minutes, start_time, end_time, status, notes)
     VALUES ($1, 'Interactive Tech Demo & Networking Break', 'Live hands-on showcase at demo booths with specialty refreshments in Grand Atrium', 'break', 3, 20, $2, $3, 'scheduled', 'Stage crew audio check during break')
     RETURNING id`,
    [liveEventId, item3Start, item3End]
  );

  const a4 = await pool.query(
    `INSERT INTO agenda_items (event_id, title, description, type, order_in_agenda, duration_minutes, start_time, end_time, status, notes)
     VALUES ($1, 'Closing Ceremony & Valedictory Address', 'Summit awards, valedictory address, and partner acknowledgments', 'closing', 4, 15, $2, $3, 'scheduled', 'Stage awards preparation')
     RETURNING id`,
    [liveEventId, item4Start, item4End]
  );
  console.log("Inserted 4 live agenda items into Neon!");

  // 8. Seed ai_scripts in Neon
  await pool.query("DELETE FROM ai_scripts WHERE event_id = $1", [liveEventId]);

  await pool.query(
    `INSERT INTO ai_scripts (event_id, agenda_item_id, script_type, title, content, version, is_approved, approved_by, created_by, tone, target_audience, ai_model)
     VALUES ($1::uuid, $2::uuid, 'opening'::script_type, 'Opening', 'Good morning, innovators, creators, and leaders! Welcome to TechNova 2026. Today, we bring together over 1,200 forward-thinking technologists under one roof. Prepare for groundbreaking discoveries, deep-dive architectural breakthroughs, and high-energy stage demonstrations. Let us declare TechNova 2026 officially open!', 1, TRUE, $3::uuid, $3::uuid, 'Motivational', 'Tech Leaders & Engineers', 'gemini')`,
    [liveEventId, a1.rows[0].id, organizerId]
  );

  await pool.query(
    `INSERT INTO ai_scripts (event_id, agenda_item_id, script_type, title, content, version, is_approved, approved_by, created_by, tone, target_audience, ai_model)
     VALUES ($1::uuid, $2::uuid, 'speaker_intro'::script_type, 'Bhautik Jogiya', 'Our keynote speaker today is a visionary builder in distributed AI systems. As Founder and Chief Architect at BliXo Tech, he has engineered high-throughput inference pipelines processing millions of operations. Please give an extraordinary TechNova welcome to Bhautik Jogiya!', 1, TRUE, $3::uuid, $3::uuid, 'Formal', 'Enterprise Architects', 'gemini')`,
    [liveEventId, a2.rows[0].id, organizerId]
  );

  await pool.query(
    `INSERT INTO ai_scripts (event_id, agenda_item_id, script_type, title, content, version, is_approved, approved_by, created_by, tone, target_audience, ai_model)
     VALUES ($1::uuid, $2::uuid, 'transition'::script_type, 'Transition', 'Thank you Bhautik for that phenomenal keynote. Up next, we are taking a 20-minute interactive networking pause. Refreshments and specialty coffee are served in the Grand Atrium. Explore the demo booths and rejoin us here at 10:45 AM sharp!', 1, TRUE, $3::uuid, $3::uuid, 'Casual', 'All Attendees', 'groq')`,
    [liveEventId, a3.rows[0].id, organizerId]
  );

  await pool.query(
    `INSERT INTO ai_scripts (event_id, agenda_item_id, script_type, title, content, version, is_approved, approved_by, created_by, tone, target_audience, ai_model)
     VALUES ($1::uuid, $2::uuid, 'closing'::script_type, 'Closing', 'What an unforgettable journey of ideas, collaboration, and inspiration today at TechNova 2026. On behalf of our organizing committee and speakers, thank you for being part of this remarkable stage. Safe travels, and see you next year!', 1, TRUE, $3::uuid, $3::uuid, 'Motivational', 'All Attendees', 'gemini')`,
    [liveEventId, a4.rows[0].id, organizerId]
  );
  console.log("Inserted 4 stage scripts into Neon ai_scripts!");

  console.log("✅ Neon Database is 100% seeded with real live conference data!");
  await pool.end();
}

seedNeon().catch((err) => {
  console.error("❌ Seed error:", err);
  process.exit(1);
});
