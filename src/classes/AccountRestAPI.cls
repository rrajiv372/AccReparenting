/**
 * REST API for Web Service used to process account re-parenting request.
 * Here this class is following a strict url mapping.
 * Versions should be used also in standard practice.
 * Best practice is to use wildcards to map dynemic urls with a fixed base url
 * so that the paths after base urls should rout to the desired handling method.
 * This should be achieved by creating a request parser.
 *
 * @author Rajiv Ranjan
 * @since June 2017
 */
@RestResource(urlMapping='/accountreparenting')
global class AccountRestAPI {
    
    
    /*
    * Gets the RestContext request
    */
    private static System.RestRequest request = System.RestContext.request;

    /*
    * Gets the RestContext response
    */
    public static System.RestResponse response = System.RestContext.response;
    
    private static Account account;
    
    private static Account parentAccount;
    
    /**
     * Processes a Http Post request to process account re-parenting
     *
     * @author Rajiv Ranjan
     * @since June 2017
     * @param OptimizeID String expected external id OptimizeID used to find the account
     * @param accName String expected name to find the parent account
     */
    @HttpPost
    global static void doPost(String OptimizeID, String  accName)
    {
        processRequest(OptimizeID, accName);
    }
    
	/**
     * Processes account re-parenting operation depending on the inputs.
	 * Here 3 SOQLs are used because of three different criteria required.
	 * Also caching is not done here (by checking field value to null), as these SQLs are called only once per criteria
     *
     * @author Rajiv Ranjan
     * @since June 2017
     * @param OptimizeID String expected external id OptimizeID used to find the account
     * @param accName String expected name to find the parent account
     */
    private static void processRequest(String OptID, String  accName)
    { 
        if(String.isBlank(OptID) || String.isBlank(accName)) //Point 4
        {
            setResponse('Fail', 'Either of OptimizeID or Account name is blank', 400);
        }
        else
        {
            // escape single quotes to prevent SOQL injection
            String OptimizeID = String.escapeSingleQuotes(OptID);
            String accountName = String.escapeSingleQuotes(accName);
            
            try
            {
                account = getAccount('OptimizeID__c = \'' + OptimizeID + '\'');        // Point 5, get account related to optimizeId
                
                if(account != null) //Point 6
                {
                    parentAccount = getAccount('OptimizeID__c != \'' + OptimizeID + '\''   // Point 6, get parent account
                                               + ' And Name = \'' + accountName + '\''
                                               + ' And ParentId = null');
                    
                    //point 7
                    //There is no else part of point 7 provided in doc,
                    //I guess it should be to create the parent account with the given Name
                    //Then update the found optimizeId account with the parent as the newly created id
                    if(parentAccount != null)
                    {
                        account.ParentId = parentAccount.Id;
                    } 
                    else{ //Adding this as per my thinking
                        Account parentAcc = new Account(Name = accountName);
                        insert parentAcc;
                        
                        account.ParentId = parentAcc.Id;
                    }
                    
                    //update account with parent id
                    update account;
                    
                    //Send success response
                    setResponse('Pass', 'Re-parenting scuccessful!', 200);
                }
                else //Point 8
                {
                    //point  8.1
                    parentAccount = getAccount('Name = \'' + accountName + '\'');
                    
                    //Point 8.2 or 8.3, create a account for both cases.
                    //what to do with account created for case 8.2 is not clear, so leaving that case.
                    account = new Account(name = accountName);
                    insert account;
                    
                    //8.3
                    if(parentAccount != null)
                    {
                        account.ParentId = parentAccount.Id;
                        update account;
                    }
                    
                    //Set response
                    setResponse('Pass', 'Partial Re-parenting scuccessful!', 200);
                }
                
            } 
            catch(DmlException e) 
            {
                //Add custom error code for error case, using 304 for not modified
                setResponse('Error', e.getMessage(), 304);
            }
        }
    }
    
    /**
     * get a specific account if some selection creteria satifies
	 * Caching should be done from the caller method
     * @author Rajiv Ranjan
     * @since June 2017
     * @param whereBlock String where block used to construct SOQL query
     * @return selected account if any found
     */
    private static Account getAccount(String whereBlock)
    {
        Account acc;
        if(String.isNotBlank(whereBlock))
        {
            List<Account> accList = Database.query('Select Id From Account Where ' + whereBlock + ' Limit 1');
            if(accList.size() == 1)
            {
                acc = accList[0];
            }
        }
        return acc;
    }
    
    /**
     * Method used to set the response data to be returned
     * @author Rajiv Ranjan
     * @since June 2017
     * @param status String specifies the request status as pass, failed or error
     * @param message String used to specify the expected message to be returned to user
     * param Integer code response status code
     */
    private static void setResponse(String status, String message, Integer code)
    {
        ResponseHandler responseData = new ResponseHandler(status, message);
        response.statusCode = code;
        response.responseBody = Blob.valueOf(Json.serialize(responseData));
    }
}