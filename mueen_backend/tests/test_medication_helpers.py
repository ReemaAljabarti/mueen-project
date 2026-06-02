# Unit Test Description:
# This test file validates medication helper functions from database.py.
#
# The tested functions are:
# 1. normalize_gtin_for_lookup()
# 2. normalize_drug_id()
#
# These helper functions were selected because they support Reema's
# Medication Management and Safety Checks functionality.
#
# normalize_gtin_for_lookup() is used before medication lookup by barcode/GTIN.
# It removes non-digit characters, extracts GTIN values when needed,
# and prepares the barcode value for database lookup.
#
# normalize_drug_id() is used before drug interaction checking.
# It standardizes drug IDs, such as converting MU1 into MU001,
# so interaction matching can be more consistent.
#
# Six test cases are included:
# 1. A 14-digit GTIN starting with 0 should be converted to 13 digits.
# 2. A GTIN with spaces and dashes should be cleaned.
# 3. An invalid GTIN without digits should return an empty string.
# 4. A short MU drug ID should be normalized to three digits.
# 5. A lowercase MU drug ID should be converted to uppercase and normalized.
# 6. A non-MU drug ID should be returned as cleaned uppercase text.

# Import the helper functions that will be tested.
from database import normalize_gtin_for_lookup, normalize_drug_id


# Test case 1:
# This test checks how the function handles a 14-digit GTIN that starts with 0.
def test_normalize_gtin_removes_leading_zero_from_14_digits():
    # Arrange:
    # Define a 14-digit GTIN that starts with 0.
    gtin = "01234567890123"

    # Act:
    # Normalize the GTIN using the helper function.
    result = normalize_gtin_for_lookup(gtin)

    # Assert:
    # The function should remove the first 0 and return 13 digits.
    assert result == "1234567890123"


# Test case 2:
# This test checks that spaces and dashes are removed from the GTIN.
def test_normalize_gtin_removes_spaces_and_dashes():
    # Arrange:
    # Define a GTIN with spaces and dashes.
    gtin = " 123-456 789-0123 "

    # Act:
    # Normalize the GTIN using the helper function.
    result = normalize_gtin_for_lookup(gtin)

    # Assert:
    # The result should contain digits only.
    assert result == "1234567890123"


# Test case 3:
# This test checks that invalid GTIN input returns an empty string.
def test_normalize_gtin_invalid_text_returns_empty_string():
    # Arrange:
    # Define an invalid GTIN with no digits.
    gtin = "abc"

    # Act:
    # Normalize the invalid GTIN.
    result = normalize_gtin_for_lookup(gtin)

    # Assert:
    # Since there are no digits, the function should return an empty string.
    assert result == ""


# Test case 4:
# This test checks that a short MU drug ID is normalized to three digits.
def test_normalize_drug_id_short_mu_id():
    # Arrange:
    # Define a short drug ID.
    drug_id = "MU1"

    # Act:
    # Normalize the drug ID.
    result = normalize_drug_id(drug_id)

    # Assert:
    # MU1 should become MU001.
    assert result == "MU001"


# Test case 5:
# This test checks that lowercase input is converted to uppercase and normalized.
def test_normalize_drug_id_lowercase_mu_id():
    # Arrange:
    # Define a lowercase drug ID with extra spaces.
    drug_id = " mu25 "

    # Act:
    # Normalize the drug ID.
    result = normalize_drug_id(drug_id)

    # Assert:
    # The result should be uppercase and padded to three digits.
    assert result == "MU025"


# Test case 6:
# This test checks that non-MU values are only cleaned and uppercased.
def test_normalize_drug_id_non_mu_value():
    # Arrange:
    # Define a non-MU drug ID.
    drug_id = " panadol "

    # Act:
    # Normalize the drug ID.
    result = normalize_drug_id(drug_id)

    # Assert:
    # Since it does not start with MU, it should be returned as uppercase text.
    assert result == "PANADOL"
    