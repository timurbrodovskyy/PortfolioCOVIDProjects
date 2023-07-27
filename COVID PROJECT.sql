-- CREATION OF THE TABLES
Use project;

Create Table covid_deaths
(IsoCode varchar(255),
Contitnet varchar(255),
Location varchar(255),
Date_ date,
Population int,
TotalCases int,
NewCases int,
NewCasesSmoothes int,
TotalDeaths int,
NewDeaths int,
NewDeathsSmoothed int,
TotalCasesPerMil int,
NewCasesPerMil int,
NewCasesSmoothedPerMil int,
TotalDeathsPerMil int,
NewDeathsPerMil int,
NewDeathsSmoothedPerMil int,
ReproductionRate int,
IcuPatients int,
IcuPatientsPerMil int,
HospPatients int,
HospPatientsPerMil int,
WeeklyIcuAdmissions int,
WeeklyIcuAdmissionsPerMil int,
WeeklyHospAdmissions int,
WeeklyHospAdmissionsPerMil int
)

Select *
From covid_deaths;

Set sql_safe_updates=0;

SET sql_mode = "";

Load Data InFile 'Covid DeathsCSV2.csv' into table covid_deaths
Fields terminated By ','
Ignore 1 Lines;



Create Table covid_vaccinations
(IsoCode varchar(255),
Contitnet varchar(255),
Location varchar(255),
Date_ date,
TotalTests int,
NewTests int,
TotalTestsPerThousand int,
NewTestsPerThousand int,
NewTestsSmoothed int,
NewTestsSmoothedPerThousand int,
PositiveRate int,
TestsPerCase int,
TestsUnits int,
TotalVaccinations int,
PeopleVaccinated int,
PeopleFullyVaccinated int,
TotalBoosters int,
NewVaccinations int,
NewVaccinationsSmoothed int,
TotalVaccinationsPerHundred int,
PeopleVaccinatedPerHundred int,
PeopleFullyVaccinatedPerHundred int,
TotalBoostersPerHundred int,
NewVaccinationsSmoothedPerMillion int,
NewPeopleVaccinatedSmoothed int,
NewPeopleVacinatedSmoothedPerHundred int,
StringencyIndex int,
PopulationDensity int,
MeadianAge int,
Aged_65_older int,
Aged_70_older int,
GdpPerCapita int,
ExtremePoverty int,
CardiovascDeathRate int,
DiabetesPrevalence int,
FemaleSmokers int,
MaleSmokers int,
HandWashingFacilities int,
HospitalBedsPerThousand int,
LifeExpectancy int,
HumanDevelopmentIndex int,
ExcessMortalityCumulativeAbsolute int,
ExcessMortalityCumulative int,
ExcessMortality int,
ExcessMortalityCumulativePerMillion int
	)
    
    Select *
    from covid_vaccinations;
    
Load Data InFile 'Covid vaccinations.csv' into table covid_vaccinations
Fields terminated By ','
Ignore 1 Lines;


-- 

/* Select *
From covid_vaccinations
Order by 3,4 */

/* Select *
From covid_Deaths
Where Continent <> ''
Order by 3,4 */

Select Location, Date_, totalCases, newCases, totalDeaths, population
From covid_Deaths
Where Continent <> ''
Order By 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows liklihood of dying if you contract covid in your country

Select Location, Date_, totalCases, totalDeaths, ((totalDeaths/totalCases)*100) as DeathPercentage
From covid_Deaths
Where location like '%Netherlands%' and Continent <> ''
Order By 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select Location, Date_, population, totalCases, ((totalcases/population)*100) as CasesPercentage
From covid_Deaths
Where location like '%Netherlands%' and Continent <> ''
Order By 1,2

-- Looking at countries with the Highest Infection Rate Compared to Population

Select Location, Population, MAX(totalCases) as HighestInfectionCount, (MAX(totalcases/population)*100) as PercentPopulationInfected
From covid_Deaths
Group by Location, population
Order By PercentPopulationInfected desc

-- Showing Countries with the Highest Death Count per Population

Select Location, MAX(TotalDeaths) as TotalDeathCount
From covid_Deaths
Where Continent <> ''
Group by Location
Order By TotalDeathCount desc

-- Breaking things down by Continent
-- Showing the Continents with the highest Deatch Count

Select continent, MAX(TotalDeaths) as TotalDeathCount
From covid_Deaths
Where Continent <> ''
Group by continent
Order By TotalDeathCount desc

-- GLOBAL NUMBERS

-- Death percentage per case based on each date

Select Date_, SUM(NewCases) as TotalCases, SUM(NewDeaths) as TotalDeaths, SUM(NewDeaths)/SUM(NewCases)*100 as DeathPercentage
From covid_Deaths
Where Continent <> ''
Group By Date_
Order By 1,2

-- Death percentage for the whole time

Select SUM(NewCases) as TotalCases, SUM(NewDeaths) as TotalDeaths, SUM(NewDeaths)/SUM(NewCases)*100 as DeathPercentage
From covid_Deaths
Where Continent <> ''
Order By 1,2




-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date_, dea.population, vac.NewVaccinations, SUM(vac.NewVaccinations) over(Partition by dea.location order by dea.location, dea.date_) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
On dea.location = vac.location
and dea.date_ = vac.date_
Where dea.Continent <> ''
Order by 2,3


-- USE CTE

With PopvsVac (Continent, Location, Date_, Population, NewVaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date_, dea.population, vac.NewVaccinations, SUM(vac.NewVaccinations) over(Partition by dea.location order by dea.location, dea.date_) as RollingPeopleVaccinated
From covid_deaths dea
Join covid_vaccinations vac
On dea.location = vac.location
and dea.date_ = vac.date_
Where dea.Continent <> ''
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- TEMP TABLE

Drop table if exists PercentPopulationVaccinated
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date_ DATE,
    Population DECIMAL(18, 2),
    NewVaccinations DECIMAL(18, 2),
    RollingPeopleVaccinated DECIMAL(18, 2)
);

INSERT INTO PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date_,
    dea.population,
    vac.NewVaccinations,
    SUM(vac.NewVaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac ON dea.location = vac.location AND dea.date_ = vac.date_
WHERE dea.Continent <> '';

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT
    dea.continent,
    dea.location,
    dea.date_,
    dea.population,
    vac.NewVaccinations,
    SUM(vac.NewVaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac ON dea.location = vac.location AND dea.date_ = vac.date_
WHERE dea.Continent <> '';

Create View DeathPercentageNetherlands as
Select Location, Date_, totalCases, totalDeaths, ((totalDeaths/totalCases)*100) as DeathPercentage
From covid_Deaths
Where location like '%Netherlands%' and Continent <> ''
Order By 1,2

Create View CasesPercentageNetherlands as
Select Location, Date_, population, totalCases, ((totalcases/population)*100) as CasesPercentage
From covid_Deaths
Where location like '%Netherlands%' and Continent <> ''
Order By 1,2

Create View PercentPopulationInfected as
Select Location, Population, MAX(totalCases) as HighestInfectionCount, (MAX(totalcases/population)*100) as PercentPopulationInfected
From covid_Deaths
Group by Location, population
Order By PercentPopulationInfected desc

Create View TotalDeathCount as
Select Location, MAX(TotalDeaths) as TotalDeathCount
From covid_Deaths
Where Continent <> ''
Group by Location
Order By TotalDeathCount desc

Create View TotalDeathCountContinents as
Select continent, MAX(TotalDeaths) as TotalDeathCount
From covid_Deaths
Where Continent <> ''
Group by continent
Order By TotalDeathCount desc
