SELECT * FROM CovidDeaths
WHERE continent is not null
ORDER BY 3, 4

SELECT * FROM CovidVaccinations
ORDER BY 3, 4

-- Select Data that we are going to be starting with
SELECT location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in Indonesia
SELECT location, 
	date, 
	total_cases, 
	total_deaths, 
	ISNULL(CONVERT(VARCHAR, ((total_deaths/total_cases)*100)), '-') AS [DeathPercentage] 
FROM CovidDeaths
WHERE location LIKE '%indo%'
AND continent IS NOT NULL
ORDER BY 1,2



-- Total Cases vs Population
-- Shows percentage of population got covid
SELECT location, 
	date, 
	total_cases, 
	population,
	(total_cases/population)*100 AS [Percentage of Population Infected] 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT location,  
	population,
	MAX(total_cases) AS [HighestInfectionCount],
	MAX(total_cases/population)*100 AS [Percentage of Population Infected] 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY [Percentage of Population Infected] DESC


-- Countries with Highest Death Count per Population
SELECT location,  
	MAX(CONVERT(INT, total_deaths)) AS [TotalDeathCount]
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY [TotalDeathCount] DESC




-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with the highest dead count per population
SELECT continent,  
MAX(CONVERT(INT, total_deaths)) AS [TotalDeathCount]
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY [TotalDeathCount] DESC

-- Global Numbers calculated per day:
SELECT 
	date,
	SUM(new_cases) AS [Total Cases],
	SUM(CONVERT(FLOAT, new_deaths)) AS [Total Deaths],
	SUM(CONVERT(FLOAT, new_deaths))/SUM(new_cases) * 100 AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Global numbers:
SELECT 
	SUM(new_cases) AS [Total Cases],
	SUM(CONVERT(FLOAT, new_deaths)) AS [Total Deaths],
	SUM(CONVERT(FLOAT, new_deaths))/SUM(new_cases) * 100 AS [Death Percentage]
FROM CovidDeaths
WHERE continent IS NOT NULL

-- Showing Numbers of People Vaccinated
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [RollingPeopleVaccinated]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

-- Total Population vs Vaccinations
-- Using CTE to show the population
WITH PopVSVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS(
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [RollingPeopleVaccinated]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *,
(RollingPeopleVaccinated/Population) * 100 AS [Percentage of People Vaccinated]
FROM PopVSVac


-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_Vaccinations NUMERIC,
	RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [RollingPeopleVaccinated]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date


SELECT *,
(RollingPeopleVaccinated/Population) * 100 AS [Percentage of People Vaccinated]
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	CD.continent, 
	CD.location,  
	CD.date, 
	CD.population, 
	CV.new_vaccinations,
	SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) AS [RollingPeopleVaccinated]
FROM CovidDeaths CD
JOIN CovidVaccinations CV ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated