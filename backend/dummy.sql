-- ==========================================
-- 1. POPULATE LOOKUP & PRIMARY ENTITIES
-- ==========================================

-- Populate Patient
INSERT INTO Patient (first_name, last_name, dob, condition) VALUES 
('John', 'Doe', '1980-05-15', 'Glaucoma'),
('Jane', 'Smith', '1992-09-23', 'Chronic Dry Eye'),
('Alice', 'Johnson', '1965-11-02', 'Ocular Hypertension');

-- Populate Caregiver_roles
INSERT INTO Caregiver_roles (role_name) VALUES 
('doctor'),
('family'),
('friend');

-- Populate Caregiver
INSERT INTO Caregiver (name) VALUES 
('Dr. Robert Chen'),
('Mary Doe'),
('Sarah Lin');

-- Populate Medication (Liquid Drops Counted by Volume capacity)
INSERT INTO Medication (name, manufacturer, num_drops) VALUES 
('Latanoprost', 'Pfizer', 125),   -- e.g., 2.5ml bottle approx 125 drops
('Timolol', 'Novartis', 250),     -- e.g., 5ml bottle approx 250 drops
('Restasis', 'Allergan', 60);     -- Single-use vials total pack drops

-- Populate Pharmacy
INSERT INTO Pharmacy (latitude, longitude, phone_number, website) VALUES 
(37.7749, -122.4194, '555-0192', 'https://www.cvs-downtown.com'),
(37.7833, -122.4167, '555-0143', 'https://www.walgreens-sf.com');

-- Populate Clinic
INSERT INTO Clinic (business_name, longitude, latitude) VALUES 
('Bay Area Eye Care', -122.4089, 37.7892),
('Clear Vision Institute', -122.4312, 37.7651);


-- ==========================================
-- 2. POPULATE DEPENDENT & BRIDGE TABLES
-- ==========================================

-- Populate Caregiver Role Assignments (Supporting many-to-many)
INSERT INTO Caregiver_role_assignment (caregiver_id, role_id) VALUES 
(1, 1), -- Dr. Chen is a doctor
(2, 2), -- Mary Doe is family
(2, 3), -- Mary Doe is also a friend (Dual Role)
(3, 3); -- Sarah Lin is a friend

-- Populate PressureReadings
INSERT INTO PressureReadings (patient_id, timestamp, value) VALUES 
(1, '2026-05-28 09:00:00', 16.5),
(1, '2026-05-29 09:15:00', 17.2),
(3, '2026-05-29 14:30:00', 21.0);

-- Populate Appointment
INSERT INTO Appointment (start_timestamp, end_timestamp, patient_id, caregiver_id) VALUES 
('2026-06-05 10:00:00', '2026-06-05 10:30:00', 1, 1),
('2026-06-12 11:15:00', '2026-06-12 12:00:00', 2, 3);

-- Populate Prescription
INSERT INTO Prescription (drug_name, dosage, caregiver_id, medication_id, patient_id, start_date, end_date) VALUES 
('Latanoprost 0.005%', '1 drop in affected eye(s) once daily in the evening', 1, 1, 1, '2026-05-01', '2026-11-01'),
('Timolol Maleate 0.5%', '1 drop twice daily', 1, 2, 3, '2026-05-15', '2026-08-15');

-- Populate dose (Logs tracking when user has actually taken medication)
INSERT INTO dose (timestamp, prescription_id) VALUES 
('2026-05-29 21:05:00', 1), -- John took his Latanoprost last night
('2026-05-30 08:00:00', 2), -- Alice took her morning Timolol
('2026-05-30 20:15:00', 1); -- John took his Latanoprost tonight

-- Populate stock
INSERT INTO stock (pharmacy_id, medication_id, in_stock, estimated_price) VALUES 
(1, 1, 45, 24.99),
(1, 2, 12, 18.50),
(2, 1, 30, 26.00),
(2, 3, 8, 145.00);

-- Populate Clinic_services
INSERT INTO Clinic_services (clinic_id, service_name, estimated_fee) VALUES 
(1, 'Comprehensive Eye Exam', 120.00),
(1, 'Glaucoma Screening', 85.00),
(2, 'LASIK Consultation', 0.00);

-- Populate OpeningHours
INSERT INTO OpeningHours (day, start_time, end_time, business_id) VALUES 
('Monday', '08:00', '18:00', 1),    -- Pharmacy 1 Hours
('Tuesday', '08:00', '18:00', 1),   
('Monday', '09:00', '17:00', 2),    -- Pharmacy 2 or Clinic 1 Hours
('Wednesday', '09:00', '17:00', 2);