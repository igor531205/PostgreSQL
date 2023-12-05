-- Name: CLEAR Database: 

DROP TABLE IF EXISTS Airports CASCADE;
DROP TABLE IF EXISTS Events CASCADE;
DROP TABLE IF EXISTS Airlines CASCADE;
DROP TABLE IF EXISTS Aircrafts CASCADE;
DROP TABLE IF EXISTS Flights CASCADE;
DROP TABLE IF EXISTS Airports_Flights CASCADE;
DROP TABLE IF EXISTS Crew_members CASCADE;
DROP TABLE IF EXISTS Crews CASCADE;
DROP TABLE IF EXISTS Crews_Crew_members CASCADE;

-- Name: Airports; Type: TABLE; Schema: public; Tablespace:  

CREATE TABLE Airports (
    airport_id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    international_code VARCHAR(5)
);


-- Name: Airlines; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Airlines (
    airline_id SERIAL PRIMARY KEY,
    name VARCHAR(50)
);


-- Name: Aircrafts; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Aircrafts (
    aircraft_id SERIAL PRIMARY KEY,
    number VARCHAR(50),
    brand VARCHAR(50),
    model VARCHAR(50),
    capacity INT
);


-- Name: Flights; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Flights (
    flight_id SERIAL PRIMARY KEY,
    airline_id INT REFERENCES Airlines(airline_id),
    aircraft_id INT REFERENCES Aircrafts(aircraft_id),
    flight_number VARCHAR(50),
    type VARCHAR(50),
    range INT,
    departure_time TIMESTAMP,
    arrival_time TIMESTAMP,
    travel_time INTERVAL,
    frequency VARCHAR(100)
);


-- Name: Events; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Events (
    event_id SERIAL PRIMARY KEY,
    airport_id INT REFERENCES Airports(airport_id),
	flight_id INT REFERENCES Flights(flight_id),
    type VARCHAR(50),
    date DATE,
    del_adv_time TIME,
    status VARCHAR(50)
);


-- Name: Airports_Flights; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Airports_Flights (
    airport_id INT REFERENCES Airports(airport_id),
    flight_id INT REFERENCES Flights(flight_id),
    PRIMARY KEY (airport_id, flight_id)
);


-- Name: Crew_members; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Crew_members (
    crew_member_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    position VARCHAR(100),
    number_of_flights INT
);


-- Name: Crews; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Crews (
    crew_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES Flights(flight_id),
    name VARCHAR(255),
    time_of_flight INTERVAL
);


-- Name: Crews_Crew_members; Type: TABLE; Schema: public; Tablespace: 

CREATE TABLE Crews_Crew_members (
    crew_id INT REFERENCES Crews(crew_id),
    crew_member_id INT REFERENCES Crew_members(crew_member_id),
    PRIMARY KEY (crew_id, crew_member_id)
);