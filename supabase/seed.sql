-- Starter ratings, attributed to a fixed "site" member whose secret is unusable.
insert into public.members(id, secret_hash)
values ('00000000-0000-0000-0000-000000000001', 'starter-no-login')
on conflict (id) do nothing;

insert into public.readers(id, nickname)
values ('00000000-0000-0000-0000-000000000001', 'דירוג פתיחה של האתר')
on conflict (id) do update set nickname = excluded.nickname;

insert into public.ratings(id, title, inputs, score, raw_score, veto, created_by, created_at, updated_at) values
('00000000-0000-0000-0001-000000000001', 'הארי פוטר ואבן החכמים',
 '{"pages":320,"pov":5,"percentage":0,"unexpected":1,"apathy":5,"mainEvents":0,"mainExplicit":0,"mainInitiative":0,"secondary":[]}', 0, 0, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:01Z', '2026-11-17T10:00:01Z'),
('00000000-0000-0000-0001-000000000002', 'הארי פוטר והנסיך חצוי הדם',
 '{"pages":650,"pov":5,"percentage":0.02,"unexpected":1,"apathy":4,"mainEvents":3,"mainExplicit":1,"mainInitiative":2,"secondary":[{"ev":4,"ex":1,"ini":1}]}', 0.42, 0.007, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:02Z', '2026-11-17T10:00:02Z'),
('00000000-0000-0000-0001-000000000003', 'משחקי הרעב',
 '{"pages":380,"pov":3,"percentage":0.05,"unexpected":1,"apathy":4,"mainEvents":5,"mainExplicit":1,"mainInitiative":1,"secondary":[]}', 0.88, 0.01667, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:03Z', '2026-11-17T10:00:03Z'),
('00000000-0000-0000-0001-000000000004', 'דמדומים',
 '{"pages":500,"pov":3,"percentage":0.05,"unexpected":1,"apathy":4,"mainEvents":4,"mainExplicit":1,"mainInitiative":3,"secondary":[]}', 1.06, 0.02083, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:04Z', '2026-11-17T10:00:04Z'),
('00000000-0000-0000-0001-000000000005', 'גאווה ודעה קדומה',
 '{"pages":430,"pov":5,"percentage":0.02,"unexpected":1,"apathy":5,"mainEvents":0,"mainExplicit":0,"mainInitiative":0,"secondary":[{"ev":1,"ex":1,"ini":3}]}', 0.25, 0.004, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:05Z', '2026-11-17T10:00:05Z'),
('00000000-0000-0000-0001-000000000006', 'הנסיך הקטן',
 '{"pages":96,"pov":3,"percentage":0,"unexpected":1,"apathy":5,"mainEvents":0,"mainExplicit":0,"mainInitiative":0,"secondary":[]}', 0, 0, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:06Z', '2026-11-17T10:00:06Z'),
('00000000-0000-0000-0001-000000000007', '1984',
 '{"pages":330,"pov":5,"percentage":0.1,"unexpected":1,"apathy":3,"mainEvents":4,"mainExplicit":2,"mainInitiative":2,"secondary":[{"ev":4,"ex":2,"ini":3}]}', 2.79, 0.08667, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:07Z', '2026-11-17T10:00:07Z'),
('00000000-0000-0000-0001-000000000008', 'יומנה של אנה פרנק',
 '{"pages":340,"pov":3,"percentage":0.02,"unexpected":1,"apathy":4,"mainEvents":3,"mainExplicit":1,"mainInitiative":2,"secondary":[]}', 0.4, 0.00667, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:08Z', '2026-11-17T10:00:08Z'),
('00000000-0000-0000-0001-000000000009', 'שר הטבעות: אחוות הטבעת',
 '{"pages":480,"pov":5,"percentage":0,"unexpected":1,"apathy":5,"mainEvents":0,"mainExplicit":0,"mainInitiative":0,"secondary":[]}', 0, 0, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:09Z', '2026-11-17T10:00:09Z'),
('00000000-0000-0000-0001-000000000010', 'התפסן בשדה השיפון',
 '{"pages":230,"pov":3,"percentage":0.05,"unexpected":1,"apathy":4,"mainEvents":2,"mainExplicit":1,"mainInitiative":1,"secondary":[]}', 0.69, 0.0125, false,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:10Z', '2026-11-17T10:00:10Z'),
('00000000-0000-0000-0001-000000000011', 'חמישים גוונים של אפור',
 '{"pages":520,"pov":3,"percentage":0.45,"unexpected":1,"apathy":1,"mainEvents":15,"mainExplicit":3,"mainInitiative":2,"secondary":[]}', 7.59, 1.05, true,
 '00000000-0000-0000-0000-000000000001', '2026-11-17T10:00:11Z', '2026-11-17T10:00:11Z')
on conflict (id) do nothing;
