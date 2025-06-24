-- Sample characters for dev environment with inventory persistence

INSERT INTO characters (id, steamid64, name, model, faction, is_dead, backstory, notes, inventory) VALUES
(1, '76561198000000001', 'John Walker', 'models/Humans/Group01/male_02.mdl', 'Citizen', 0, 'Former factory worker.', 'Stable. No incidents.', '{"flashlight":1,"bandage":1}'),
(2, '76561198000000002', 'Elena Voss', 'models/Humans/Group01/female_06.mdl', 'Citizen', 0, 'University dropout turned scavenger.', 'Watch for theft.', '{"flashlight":1,"bandage":1}'),
(3, '76561198000000003', 'C17-CP.04.933', 'models/police.mdl', 'Civil Protection', 0, 'Transferred from C18.', 'Promoted recently.', '{"stunstick":1,"radio":1}'),
(4, '76561198000000004', 'OWS-88', 'models/combine_soldier.mdl', 'Overwatch', 1, 'Killed in skirmish at sector 6.', 'Deceased.', '{"pulse_rifle":1}'),
(5, '76561198000000005', 'Gerry Mason', 'models/Humans/Group01/male_07.mdl', 'Citizen', 0, 'Local shopkeeper.', 'Friendly.', '{"flashlight":1,"bandage":1}'),
(6, '76561198000000001', 'Alias Nova', 'models/Humans/Group01/female_02.mdl', 'Citizen', 1, 'Died in a fall.', 'Accidental death. No foul play.', '{"flashlight":1,"bandage":1}');
