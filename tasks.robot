*** Settings ***
Documentation       Complete supply chain challenge.

Library             Collections
Library             RPA.Browser.Playwright
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Robocorp.Vault
Library             RPA.Tables
Library             String


*** Variables ***
${AGENT_EXCEL_PATH}=        ${OUTPUT_DIR}${/}agents.xlsx
${PROCUREMENT_URL}=         https://developer.automationanywhere.com/challenges/AutomationAnywhereLabs-POTrackingLogin.html
${PURCHASE_ORDERS_URL}=     https://developer.automationanywhere.com/challenges/automationanywherelabs-supplychainmanagement.html


*** Tasks ***
Complete supply chain challenge
    ${procurement_website}=    Open procurement website
    Log in    ${procurement_website}
    ${po_website}=    Open purchase orders website
    ${agents}=    Get agents    ${po_website}
    Fill in purchase orders
    ...    ${agents}
    ...    ${procurement_website}
    ...    ${po_website}
    Take a screenshot of the result


*** Keywords ***
Open procurement website
    New Context    userAgent=Chrome/92.0.4515.159
    ${procurement_website}=    New Page    ${PROCUREMENT_URL}
    Accept cookies
    RETURN    ${procurement_website}

Accept cookies
    Click    css=#onetrust-accept-btn-handler    noWaitAfter=True

Open purchase orders website
    ${po_website}=    New Page    ${PURCHASE_ORDERS_URL}
    RETURN    ${po_website}

Log in
    [Arguments]    ${procurement_website}
    Switch Page    ${procurement_website}
    ${secret}=    Get Secret    supplyChainChallenge
    Fill Text    css=#inputEmail    ${secret}[username]
    Fill Secret    css=#inputPassword    ${secret}[password]
    Click    css=.btn-primary

Get agents
    [Arguments]    ${po_website}
    Switch Page    ${po_website}
    ${excel_url}=    Get Attribute    css=.challenge-intro a.btn    href
    RPA.HTTP.Download    ${excel_url}    ${AGENT_EXCEL_PATH}    overwrite=True
    Open Workbook    ${AGENT_EXCEL_PATH}
    ${agents}=    Read Worksheet As Table
    Close Workbook
    RETURN    ${agents}

Fill in purchase orders
    [Arguments]    ${agents}    ${procurement_website}    ${po_website}
    ${po_numbers}=    Get purchase order numbers
    FOR    ${index}    ${po_number}    IN ENUMERATE    @{po_numbers}    start=1
        Complete purchase order
        ...    ${index}
        ...    ${po_number}
        ...    ${agents}
        ...    ${procurement_website}
        ...    ${po_website}
    END
    Click    css=#submitbutton    force=True    noWaitAfter=True

Get purchase order numbers
    ${po_numbers}=    Create List
    ${purchase_order_element_ids}=
    ...    Evaluate
    ...    [f"PONumber{number}" for number in range(1, 8)]
    FOR    ${id}    IN    @{purchase_order_element_ids}
        ${po_number}=    Get Text    css=#${id}
        Append To List    ${po_numbers}    ${po_number}
    END
    RETURN    ${po_numbers}

Complete purchase order
    [Arguments]
    ...    ${index}
    ...    ${po_number}
    ...    ${agents}
    ...    ${procurement_website}
    ...    ${po_website}
    Search purchase order    ${procurement_website}    ${po_number}
    ${state}=    Get Text    css=#dtBasicExample td:nth-child(5)
    ${agent_name}=    Get agent full name by state    ${agents}    ${state}
    ${ship_date}=    Get Text    css=#dtBasicExample td:nth-child(7)
    ${order_total}=    Get Text    css=#dtBasicExample td:nth-child(8)
    ${order_total}=    Remove String    ${order_total}    $
    Fill in purchase order
    ...    ${po_website}
    ...    ${index}
    ...    ${ship_date}
    ...    ${order_total}
    ...    ${agent_name}

Search purchase order
    [Arguments]    ${procurement_website}    ${po_number}
    Switch Page    ${procurement_website}
    Fill Text    css=#dtBasicExample_filter input    ${po_number}

Get agent full name by state
    [Arguments]    ${agents}    ${state}
    ${rows}=    Find Table Rows    ${agents}    0    ==    ${state}
    ${row}=    Get Table Row    ${rows}    ${0}
    ${agent_name}=    Set Variable    ${row}[B]
    RETURN    ${agent_name}

Fill in purchase order
    [Arguments]
    ...    ${po_website}
    ...    ${index}
    ...    ${ship_date}
    ...    ${order_total}
    ...    ${agent_name}
    Switch Page    ${po_website}
    Fill Text    css=#shipDate${index}    ${ship_date}
    Fill Text    css=#orderTotal${index}    ${order_total}
    Select Options By    css=#agent${index}    value    ${agent_name}

Take a screenshot of the result
    Take Screenshot
    ...    filename=${OUTPUT_DIR}${/}result.png
    ...    selector=css=.modal-content
