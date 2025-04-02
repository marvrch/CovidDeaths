/*
COVID-19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- 1) Preview the dataset to understand what information is available in the CovidDeaths and CovidVaccinations tables
SELECT * 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4


SELECT * 
FROM CovidVaccinations
ORDER BY 3, 4


SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 




-- FIRST, LET'S TRY EXPLORE THE DATA IN COVIDDEATHS TABLE

-- 2) Total Cases, Total Deaths, and Death Percentage in Indonesia
-- Desc: 
	-- Shows the likelihood of dying if you contract COVID-19 in Indonesia. 
	-- Death percentage is calculated from the total number of deaths divided by the total number of cases,  then multiplied by 100 to get the percentage. If the result is NULL, it will be shown as '-'.
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	ISNULL(CONVERT(VARCHAR, ((total_deaths/total_cases)*100)), '-') AS [DeathPercentage] 
FROM CovidDeaths
WHERE location LIKE '%indo%'
AND continent IS NOT NULL
ORDER BY 1,2




-- ANALYZING DATA BY COUNTRY

-- 3) Total Cases, Population, and Percentage of Population Infected in Each Country
-- Desc: Shows percentage of population got infected by COVID-19. Calculated by dividing total cases by population, then multiplying by 100.
SELECT 
	location, 
	date, 
	total_cases, 
	population,
	(total_cases/population) * 100 AS [Percentage of Population Infected] 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- 4) Countries with the Highest COVID-19 Infection Rate Relative to Population
-- Desc: Shows countries with the highest percentage of their population infected, based on total cases divided by population.
SELECT 
	location,  
	population,
	MAX(total_cases) AS [HighestInfectionCount],
	MAX(total_cases)/population * 100 AS [Percentage of Population Infected] 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY [Percentage of Population Infected] DESC


-- 5) Countries with the Highest Death Count
-- Desc: Shows countries with the highest number of total COVID-19 deaths, using the maximum recorded value per country.
SELECT 
	location,  
	MAX(CONVERT(INT, total_deaths)) AS [TotalDeathCount]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY [TotalDeathCount] DESC




-- ANALYZING DATA BY CONTINENT

-- 6) Total Death Count By Continent
-- Desc: Shows total COVID-19 death count per continent.
SELECT 
	continent,  
	MAX(CONVERT(INT, total_deaths)) AS [TotalDeathCount]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY [TotalDeathCount] DESC



-- 7) Global Daily Total of COVID-19 Cases, Deaths, and Death Percentage
-- Desc: Death percentage is calculated by dividing total deaths by total cases for each day, then multiplying by 100.
SELECT 
	date,
	SUM(new_cases) AS [Total Cases],
	SUM(CONVERT(FLOAT, new_deaths)) AS [Total Deaths],
	SUM(CONVERT(FLOAT, new_deaths))/SUM(new_cases) * 100 AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- 8)  Total Global COVID-19 Cases, Deaths, and Death Percentage
-- Desc: Shows total global COVID-19 cases and deaths. 
SELECT 
	SUM(new_cases) AS [Total Cases],
	SUM(CONVERT(FLOAT, new_deaths)) AS [Total Deaths],
	SUM(CONVERT(FLOAT, new_deaths))/SUM(new_cases) * 100 AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL




-- NOW, WE'RE GOING TO EXPLORE THE DATA IN COVIDVACCINATIONS TABLE

-- 9) Total and Cumulative Number of People Vaccinated per Country
-- Desc: 
	-- Shows the number of people vaccinated per day (new_vaccinations) and the cumulative total vaccinations (rolling) by country.
	-- The rolling value is calculated by summing daily vaccinations over time for each country.
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [Cumulative Total Vaccinations]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3


-- 10) Vaccination Progress by Country (Total, Cumulative, and Percentage)
-- Desc: 
	-- Shows daily vaccinations, cumulative total vaccinations, and percentage of population vaccinated.
	-- Percentage of Population Vaccinated is calculated by dividing total vaccinated people by the population, then multiplying by 100.

-- Using CTE method (Common Table Expression) to calculate the CumulativeTotalVaccinations first.
WITH PopVSVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeTotalVaccinations)
AS(
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [CumulativeTotalVaccinations]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *,
(CumulativeTotalVaccinations/Population) * 100 AS [Percentage of Population Vaccinated]
FROM PopVSVac


-- 11) Creating Temp Table to Store Vaccination Data
-- Desc: 
	-- Creates a temporary table to store population, daily vaccination data, and cumulative total vaccinations.
	-- WHY? This approach improves performance by avoiding repeated calculations from joins in later queries.

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_Vaccinations NUMERIC,
	CumulativeTotalVaccinations NUMERIC
)

-- Insert the data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [CumulativeTotalVaccinations]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date

-- Now, retrieve the data from the temporary table to calculate the percentage of people vaccinated.
SELECT 
	*,
	(CumulativeTotalVaccinations/Population) * 100 AS [Percentage of People Vaccinated]
FROM #PercentPopulationVaccinated


-- 12) Creating a SQL View to store vaccination data for future visualizations.
	-- Note: Order By is not allowed inside a view


-- (View for number 2) Total Cases, Total Deaths, and Death Percentage in Indonesia 
CREATE VIEW [Indonesia Death Percentage] AS 
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	ISNULL(CONVERT(VARCHAR, ((total_deaths/total_cases)*100)), '-') AS [DeathPercentage] 
FROM CovidDeaths
WHERE location LIKE '%indo%'
AND continent IS NOT NULL

SELECT * 
FROM [Indonesia Death Percentage]
ORDER BY 1,2


-- (View for number 3) Total Cases, Population, and Percentage of Population Infected in Each Country 
CREATE VIEW [Percentage of Population Infected By Country] AS
SELECT 
	location, 
	date, 
	total_cases, 
	population,
	(total_cases/population) * 100 AS [Percentage of Population Infected] 
FROM CovidDeaths
WHERE continent IS NOT NULL

SELECT * 
FROM [Percentage of Population Infected By Country]
ORDER BY 1,2


-- (View for number 4) Countries with the Highest COVID-19 Infection Rate Relative to Population
CREATE VIEW [Highest COVID-19 Infection Rate] AS
SELECT 
	location,  
	population,
	MAX(total_cases) AS [HighestInfectionCount],
	MAX(total_cases)/population * 100 AS [Percentage of Population Infected] 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

SELECT * 
FROM [Highest COVID-19 Infection Rate]
ORDER BY [Percentage of Population Infected] DESC


-- (View for number 5) Countries with the Highest Death Count
CREATE VIEW [Highest Death Count] AS
SELECT 
	location,  
	MAX(CONVERT(INT, total_deaths)) AS [TotalDeathCount]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

SELECT * 
FROM [Highest Death Count]
ORDER BY [TotalDeathCount] DESC


-- (View for number 6) Total Death Count By Continent
-- Desc: Shows total COVID-19 death count per continent.
CREATE VIEW [Total Death Count By Continent] AS
SELECT 
	continent,  
	MAX(CONVERT(INT, total_deaths)) AS [TotalDeathCount]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent

SELECT *
FROM [Total Death Count By Continent]
ORDER BY [TotalDeathCount] DESC


-- (View for number 7) Global Daily Total of COVID-19 Cases, Deaths, and Death Percentage
CREATE VIEW [Global Daily Total] AS
SELECT 
	date,
	SUM(new_cases) AS [Total Cases],
	SUM(CONVERT(FLOAT, new_deaths)) AS [Total Deaths],
	SUM(CONVERT(FLOAT, new_deaths))/SUM(new_cases) * 100 AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

SELECT *
FROM [Global Daily Total]
ORDER BY 1,2


-- (View for number 8)  Total Global COVID-19 Cases, Deaths, and Death Percentage
CREATE VIEW [Global Total] AS
SELECT 
	SUM(new_cases) AS [Total Cases],
	SUM(CONVERT(FLOAT, new_deaths)) AS [Total Deaths],
	SUM(CONVERT(FLOAT, new_deaths))/SUM(new_cases) * 100 AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL

SELECT * 
FROM [Global Total]


-- (View for Number 9) Total and Cumulative Number of People Vaccinated per Country 
CREATE VIEW [Cumulative Total Vaccinations] AS
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [CumulativeTotalVaccinations]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL

SELECT * 
FROM [Cumulative Total Vaccinations]


-- (View for number 10) Vaccination Progress by Country (Total, Cumulative, and Percentage)
CREATE VIEW [Vaccination Progress by Country] AS
WITH PopVSVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeTotalVaccinations)
AS(
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [CumulativeTotalVaccinations]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *,
(CumulativeTotalVaccinations/Population) * 100 AS [Percentage of Population Vaccinated]
FROM PopVSVac

SELECT * 
FROM [Vaccination Progress by Country]