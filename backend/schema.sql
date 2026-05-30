-- Disable foreign key checks temporarily to drop tables cleanly if they exist
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS OpeningHours;
DROP TABLE IF EXISTS Clinic_services;
DROP TABLE IF EXISTS stock;
DROP TABLE IF EXISTS Clinic;
DROP TABLE IF EXISTS Pharmacy;
DROP TABLE IF EXISTS dose;
DROP TABLE IF EXISTS Prescription;
DROP TABLE IF EXISTS Medication;
DROP TABLE IF EXISTS Appointment;
DROP TABLE IF EXISTS PressureReadings;
DROP TABLE IF EXISTS Caregiver_role_assignment;
DROP TABLE IF EXISTS Caregiver;
DROP TABLE IF EXISTS Caregiver_roles;
DROP TABLE IF EXISTS Patient;

PRAGMA foreign_keys = ON;

-- 1. Patient Table
CREATE TABLE Patient (
    patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    dob TEXT, 
    condition TEXT
);

-- 2. Caregiver Roles Table
CREATE TABLE Caregiver_roles (
    role_id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_name TEXT NOT NULL UNIQUE -- Contains values like 'doctor', 'family', 'friend'
);

-- 3. Caregiver Table
CREATE TABLE Caregiver (
    caregiver_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

-- 4. Caregiver Role Assignment Table (Bridge for Many-to-Many Relationship)
CREATE TABLE Caregiver_role_assignment (
    caregiver_id INTEGER,
    role_id INTEGER,
    PRIMARY KEY (caregiver_id, role_id),
    FOREIGN KEY (caregiver_id) REFERENCES Caregiver(caregiver_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES Caregiver_roles(role_id) ON DELETE CASCADE
);

-- 5. Pressure Readings Table
CREATE TABLE PressureReadings (
    reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    value REAL NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id) ON DELETE CASCADE
);

-- 6. Appointment Table
CREATE TABLE Appointment (
    appointment_id INTEGER PRIMARY KEY AUTOINCREMENT, 
    start_timestamp TEXT NOT NULL,
    end_timestamp TEXT NOT NULL,
    patient_id INTEGER NOT NULL,
    caregiver_id INTEGER,
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (caregiver_id) REFERENCES Caregiver(caregiver_id) ON DELETE SET NULL
);

-- 7. Medication Table
CREATE TABLE Medication (
    medication_id INTEGER PRIMARY KEY AUTOINCREMENT, 
    name TEXT NOT NULL,
    manufacturer TEXT,
    num_drops INTEGER -- Tracks total drops a drug has before usage
);

-- 8. Prescription Table
CREATE TABLE Prescription (
    prescription_id INTEGER PRIMARY KEY AUTOINCREMENT, 
    drug_name TEXT NOT NULL,
    dosage TEXT,
    caregiver_id INTEGER,
    medication_id INTEGER,
    patient_id INTEGER NOT NULL,
    start_date TEXT,
    end_date TEXT,
    FOREIGN KEY (caregiver_id) REFERENCES Caregiver(caregiver_id) ON DELETE SET NULL,
    FOREIGN KEY (medication_id) REFERENCES Medication(medication_id) ON DELETE SET NULL,
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id) ON DELETE CASCADE
);

-- 9. Dose Table (Logs tracking taken medications)
CREATE TABLE dose (
    dose_id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    prescription_id INTEGER NOT NULL,
    FOREIGN KEY (prescription_id) REFERENCES Prescription(prescription_id) ON DELETE CASCADE
);

-- 10. Pharmacy Table
CREATE TABLE Pharmacy (
    business_id INTEGER PRIMARY KEY AUTOINCREMENT,
    latitude REAL,
    longitude REAL,
    phone_number TEXT, -- Swapped out the duplicate website field
    website TEXT 
);

-- 11. Stock Table (Many-to-Many Bridge)
CREATE TABLE stock (
    pharmacy_id INTEGER,
    medication_id INTEGER,
    in_stock INTEGER DEFAULT 0, 
    estimated_price REAL,
    PRIMARY KEY (pharmacy_id, medication_id),
    FOREIGN KEY (pharmacy_id) REFERENCES Pharmacy(business_id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES Medication(medication_id) ON DELETE CASCADE
);

-- 12. Clinic Table
CREATE TABLE Clinic (
    business_id INTEGER PRIMARY KEY AUTOINCREMENT,
    business_name TEXT NOT NULL,
    longitude REAL,
    latitude REAL 
);

-- 13. Clinic Services Table
CREATE TABLE Clinic_services (
    clinic_id INTEGER,
    service_name TEXT NOT NULL,
    estimated_fee REAL,
    PRIMARY KEY (clinic_id, service_name),
    FOREIGN KEY (clinic_id) REFERENCES Clinic(business_id) ON DELETE CASCADE
);

-- 14. Opening Hours Table
CREATE TABLE OpeningHours (
    opening_hours_id INTEGER PRIMARY KEY AUTOINCREMENT,
    day TEXT NOT NULL,
    start_time TEXT,
    end_time TEXT,
    business_id INTEGER NOT NULL -- Links structurally to either a Pharmacy or Clinic business id
);

