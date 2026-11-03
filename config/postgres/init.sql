-- Runs once, when the postgres volume is first created. The pcas database itself comes from POSTGRES_DB.
-- The mock systems (the Underwriting Workbench, ImageRight, the GL and the rest) keep their own database, as the real systems would.
CREATE DATABASE mocks;
