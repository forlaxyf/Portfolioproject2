/*

DATA CLEANING

*/

SELECT *
FROM portfolioproject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------
------- Standardize Date Format:Change the Sale Date, take off the time at the end
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT SaleDate, convert(Date, SaleDate) 
FROM portfolioproject.dbo.NashvilleHousing

UPDATE Nashvillehousing
SET SaleDate =  convert(Date, SaleDate) 


-- except update the SaleDate coulmn directly, add a new coulmn then update into the new format
ALTER TABLE dbo.Nashvillehousing
ADD SaleDateConverted Date;

UPDATE Nashvillehousing
SET SaleDateConverted =  convert(Date, SaleDate) 

SELECT SaleDate, SaleDateConverted 
FROM portfolioproject.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------------------------
------- Populate property address data 
--------------------------------------------------------------------------------------------------------------------------------------------
SELECT * 
FROM portfolioproject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL  
 -- the property adress might not change

SELECT * 
FROM portfolioproject.dbo.NashvilleHousing
ORDER BY parcelID 
-- same id might have the same adress, fill the null property adress with same parcel id address

-- make a self-join with the same parcelID with different row
-- if the property adress is null, use same parcelID but different UniqueID's information to populate
SELECT a.parcelID, a.PropertyAddress,  b.parcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM portfolioproject.dbo.NashvilleHousing a
JOIN portfolioproject.dbo.NashvilleHousing b
	on a.parcelID = b.parcelID
	and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) -- or change b.PropertyAddress to 'NO ADDRESS' if not populate
FROM portfolioproject.dbo.NashvilleHousing a
JOIN portfolioproject.dbo.NashvilleHousing b
	on a.parcelID = b.parcelID
	and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- check if there is have null PropertyAddress
SELECT * 
FROM portfolioproject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL 



--------------------------------------------------------------------------------------------------------------------------------------------
------- Separate adress into individual column [adress, city, state]
--------------------------------------------------------------------------------------------------------------------------------------------
 -- 1: Property Address

SELECT PropertyAddress
FROM portfolioproject.dbo.NashvilleHousing 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)AS Address,  --looking at the first valur from property address until ','. -1 is for not including the ','
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))AS Address -- end at the lenth of property adress, as each adress have different length we use len()
FROM portfolioproject.dbo.NashvilleHousing 


-- separeting the column by creating other two coulmns

ALTER TABLE dbo.Nashvillehousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE Nashvillehousing
SET PropertySplitAddress =  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE dbo.Nashvillehousing
ADD PropertySplitCity Nvarchar(255);

UPDATE Nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) 



 -- 2: Owner Address

SELECT OwnerAddress
FROM portfolioproject.dbo.NashvilleHousing --Address, State, City

SELECT 
PARSENAME( REPLACE(OwnerAddress, ',' , '.') ,3), --PARSENAME only work for '.', replace ',' by '.'. and working backword than expected
PARSENAME( REPLACE(OwnerAddress, ',' , '.') ,2), -- separate by each '.' backword
PARSENAME( REPLACE(OwnerAddress, ',' , '.') ,1)
FROM portfolioproject.dbo.NashvilleHousing


ALTER TABLE dbo.Nashvillehousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE Nashvillehousing
SET OwnerSplitAddress  = PARSENAME( REPLACE(OwnerAddress, ',' , '.') ,3)


ALTER TABLE dbo.Nashvillehousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE Nashvillehousing
SET OwnerSplitCity = PARSENAME( REPLACE(OwnerAddress, ',' , '.') ,2)


ALTER TABLE dbo.Nashvillehousing
ADD OwnerSplitState Nvarchar(255);

UPDATE Nashvillehousing
SET OwnerSplitState = PARSENAME( REPLACE(OwnerAddress, ',' , '.') ,1)


 -- check result
SELECT *
FROM portfolioproject.dbo.NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------------------------
------- Change Y & N into YES & NO in sold as vacant field
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT Distinct (SoldAsVacant), count(SoldAsVacant)
FROM portfolioproject.dbo.NashvilleHousing
Group by SoldAsVacant
ORDER BY 2

-- case statement
SELECT SoldAsVacant,
Case WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 End
FROM portfolioproject.dbo.NashvilleHousing

-- update
UPDATE Nashvillehousing
SET SoldAsVacant = Case WHEN SoldAsVacant = 'Y' THEN 'Yes'
					    WHEN SoldAsVacant = 'N' THEN 'No'
					    ELSE SoldAsVacant
					    End



--------------------------------------------------------------------------------------------------------------------------------------------
------- Remove duplicates
--------------------------------------------------------------------------------------------------------------------------------------------

-- TEMP TABLE THEN DELETE
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER()OVER (
	PARTITION BY  ParcelID,   -- use unique column Like UniqueID
				  PropertyAddress,
				  SalePrice,
				  SaleDate,
				  LegalReference
				  ORDER BY UniqueID)ROW_NUM -- when there is duplicate row, row_nume = 2

FROM portfolioproject.dbo.NashvilleHousing)

DELETE 
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


--------------------------------------------------------------------------------------------------------------------------------------------
------- Delete Unused Columns
--------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM portfolioproject.dbo.NashvilleHousing

ALTER TABLE portfolioproject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress