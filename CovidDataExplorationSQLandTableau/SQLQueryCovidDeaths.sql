/* O trabalho em quest�o analisar� os dados sobre mortes e vacina��es da COVID-19 nos pa�ses do G20 desde o primeiro caso at� 28 de fevereiro
de 2022.

O G20 � um grupo formado pelos ministros de finan�as e chefes dos bancos centrais das 19 maiores economias do mundo mais a Uni�o Europeia.

O G-20 estuda, analisa e promove a discuss�o entre os pa�ses mais ricos e os emergentes sobre quest�es pol�ticas relacionadas com a promo��o 
da estabilidade financeira internacional e encaminha as quest�es que est�o al�m das responsabilidades individuais de qualquer organiza��o.

Os dados foram retirados do site Our World in Data, uma das melhores plataformas de dados socioecon�micos do mundo.
Fonte: https://ourworldindata.org/covid-deaths

Originalmente, trata-se de apenas um arquivo .csv, por�m para faciliar os trabalho, dividimos o arquivo em dois: um para avaliar as mortes
por COVID-19 e outro para avaliar as vacina��es.

Vamos iniciar verificando os dados brutos. */
SELECT * FROM CovidStats.DBO.CovidDeaths

/* Temos uma coluna para identifica��o de total de casos (total_cases) e outra para total de morte (total_death), � interessante criar uma
coluna para defini��o da porcentagem de mortes em rela��o ao n�mero de casos, para verificar a varia��o deste n�mero durante o tempo. */
SELECT (total_deaths/total_cases) FROM CovidStats.DBO.CovidDeaths
/* Opa! Encontramos um problema, uma das vari�veis est� como nvarchar, portanto � imposs�vel realizar uma divis�o, vamos mudar isso agora mesmo. */
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_deaths DECIMAL(18,0)
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_cases DECIMAL(18,0)
GO 

/* Com o erro resolvido, teremos a propor��o de mortes por casos totais em todos os locais, mas vamos olhar para o Brasil primeiro.
A multiplica��o por 100 ser� para obter o valor por porcentagem.*/
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage FROM CovidStats.DBO.CovidDeaths
WHERE location LIKE 'Brazil'
ORDER BY 1,2

/* Podemos observar que a taxa de mortalidade da COVID-19 no Brasil em 2022 fica entre 2,25% e 2,75%, mas este percentual j� foi quase 4%
de acordo com os dados de julho de 2020, o primeiro pico da pandemia no Brasil. 

2.0 Vamos analisar agora o total de casos por popula��o, analisando apenas os pa�ses do G20. A t�tulo de informa��o, os pa�ses do G20 s�o:
�frica do Sul, Argentina, Brasil, Canad�, Estados Unidos, M�xico, China, Jap�o, Coreia do Sul, �ndia, Indon�sia, Ar�bia Saudita, Turquia,
Alemanha, Fran�a, It�lia, R�ssia, Reino Unido e Austr�lia.

Como os dados trazidos s�o todos os pa�ses do mundo, vamos criar uma tabela tempor�ria para trabalhar apenas com os dados do G20. */
SELECT * INTO dbo.CovidDeathsG20
FROM CovidStats.DBO.CovidDeathsG20 
WHERE location IN ('South Africa', 'Argentina', 'Brazil', 'Canada', 'United States','Mexico', 'China',
'Japan', 'South Korea', 'India', 'Indonesia', 'Saudi Arabia', 'Turkey', 'Germany', 'France', 'Italy', 
'Russia', 'United Kingdom', 'Australia');

/* Agora poderemos trabalhar com a nossa tabela do G20. O objetivo � saber qual a % da popula��o relativa que pegou COVID, lembrando que existe
a possibilidade da mesma pessoa pegar a doen�a mais de uma vez. */
SELECT location, max(total_cases) AS TotalCases, max(population) AS population, ROUND((max(total_cases)/max(population))*100,2) as CasesPercentage
FROM CovidStats.DBO.CovidDeathsG20 
GROUP BY location
ORDER BY 4

/* Temos que a China � o pa�s mais bem colocado, com apenas 0,007% da popula��o, seguido de Indon�sia (2,01%), Ar�bia Saudita (2,10%)
e �ndia (3,08%). Como piores resultados temos Estados Unidos (23,74%), Reino Unido (27,76%) e Fran�a (33,75%). */

/* Olhando agora para a porcentagem de mortes, para ver se o padr�o se mant�m. */
SELECT location, max(total_deaths) AS TotalDeaths, max(population) AS population, round((max(total_deaths)/max(population))*100,4) as DeathPercentage
FROM CovidStats.DBO.CovidDeathsG20 
GROUP BY location
ORDER BY 4

/* O pa�s com menos mortes proporcionais � a China, seguindo a tend�ncia da an�lises dos dados, com apenas 0,0003% da popula��o morta por COVID-19.
Seguido de Coreia do Sul (0,01%), Jap�o (0,018%) e Austr�lia (0,02%). Pode-se concluir que mesmo os pa�ses n�o tendo os menores �ndices de casos,
provavelmente tem um melhor sistema de sa�de para cuidar das pessoas infectadas, resultando em menos mortes.

Do outro lado, o Brasil tem o pior resultado de mortes, 0,30% da popula��o morreu de COVID-19, seguido dos Estados Unidos (0,28%), s�o dois pa�ses
que lidaram com sobrecargas no sistema de Sa�de, ambos pela neglig�ncia e falta de estrutura para receber pacientes, resultando em mais mortes,
mesmo com menos casos proporcionais, olhando para o Brasil. 

Mas como poder�amos saber qual foi o maior pico de casos da pandemia no G20 at� hoje? Vamos verificar:

Bem como na primeira query, ser� necess�rio alterar as colunas new_deaths and new_cases para decimal.*/
ALTER TABLE CovidStats.dbo.CovidDeathsG20 ALTER COLUMN new_deaths DECIMAL(18,0)
ALTER TABLE CovidStats.dbo.CovidDeathsG20 ALTER COLUMN new_cases DECIMAL(18,0)
GO 
-- Vamos tamb�m mudar o formato da data, para tornar algo mais leg�vel:
ALTER TABLE CovidStats.dbo.CovidDeathsG20
ADD DateClean Date;
UPDATE CovidStats.dbo.CovidDeathsG20
SET DateClean = CONVERT(Date, date)

SELECT DateClean, SUM(CAST(new_cases AS int)) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidStats.DBO.CovidDeathsG20
GROUP BY DateClean
ORDER BY 2 DESC

/* � poss�vel observar que o dia 19 de janeiro de 2022 foi o maior recorde de casos entre os pa�ses do G20, com 2 milh�es e 885 mil novos casos.
A tend�ncia se mant�m, j� que o 20 dias com maiores n�meros de novos casos ocorreram todos em 2022, mostrando o tamanho do impacto da variante �micron
considerada mais transmiss�vel do que todas as outras j� registradas. 
O pico de casos em 2021 foi no dia 30 de dezembro, com 1,4 milh�o de casos e em 2020, foram registrados 613 mil casos em 31 de dezembro deste ano. 
*/

/* Vamos passar para a tabela de testes e vacina��es do G20: */
SELECT * INTO CovidStats.dbo.CovidVaxG20
FROM CovidStats.DBO.CovidVax 
WHERE location IN ('South Africa', 'Argentina', 'Brazil', 'Canada', 'United States','Mexico', 'China',
'Japan', 'South Korea', 'India', 'Indonesia', 'Saudi Arabia', 'Turkey', 'Germany', 'France', 'Italy', 
'Russia', 'United Kingdom', 'Australia');
/* Vamos utilizar um JOIN para trazer as duas tabelas (Vax e Deaths), olhando para a vacina��o total.

Gostar�amos de saber qual foi o primeiro pa�s do G20 a iniciar a vacina��o, vamos utilizar uma fun��o para isso. */

SELECT D.location, MIN(D.DateClean) AS FirstVaxDate
FROM CovidStats.dbo.CovidDeathsG20 D
JOIN CovidVaxG20 V
	ON D.location = V.location
	AND D.date = V.date
WHERE V.total_vaccinations IS NOT NULL
GROUP BY d.location
ORDER BY 2
/* O primeiro pa�s a vacinar a sua popula��o foram os Estados Unidos no dia 13 de dezembro de 2020, seguidos por Canada no dia 14 e China e R�ssia
no dia 15. Os �ltimos pa�ses a iniciarem a vacina��o foram Jap�o no dia 17 de fevereiro de 2021, Austr�lia em 21 de fevereiro e Coreia do Sul dia
26 de fevereiro. Pode-se observar exemplos de pa�ses com baixo �ndice de Mortes, como Jap�o e Austr�lia n�o tiveram tanta pressa em iniciar a 
vacina��o como os Estados Unidos, at� hoje o pa�s com maior �ndice de mortes. */

/* Para finalizar, vamos criar a primeira visualiza��o dentro do pr�prio SQL Server, no caso, vamos obter o percentual de pessoas vacinadas
por pa�s. Esta visualiza��o ser� o percentual de pessoas vacinadas no pa�s. Como j� conhecemos o problema que iremos ter, vamos alterar a coluna
new_vaccinations como decimal */

ALTER TABLE CovidStats.dbo.CovidVaxG20 ALTER COLUMN new_vaccinations DECIMAL(18,0)

CREATE VIEW PercentualPopulationVaccinated AS
Select D.continent, D.location, D.DateClean, D.population, V.new_vaccinations
, SUM(CONVERT(bigint,V.new_vaccinations)) OVER (PARTITION BY D.Location ORDER BY D.location, D.DateClean) as RollingPeopleVaccinated
FROM CovidStats.dbo.CovidDeathsG20 D
JOIN CovidStats.dbo.CovidVaxG20 V
	On d.location = V.location
	and D.date = V.date
where D.continent is not null 

