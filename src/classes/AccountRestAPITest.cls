/**
 * Unit tests for AccountRestAPI
 * Test classes should be used to test all possible scenarios
 * @author Rajiv Ranjan
 * @since June 2017
 */
@isTest
public class AccountRestAPITest {
    private static final string REQUEST_METHOD_POST = 'POST';

	/**
	 * Common data setup area for test methods
	 * Best practice is to disable triggers by using some static flags before setting-up the data
	 * 4x Accounts
	 * @author Rajiv Ranjan
	 * @since June 2017
	 */
    @testSetup
    private static void setupCommonData()
    {
        //Create Accounts
        Account nonOptimizeAcc = new Account(Name = 'Non_Opt_Acc');
        insert nonOptimizeAcc;
        
        Account optimizeAcc = new Account(Name = 'Opt_Acc', OptimizeID__c = '1234');
        Account optimizeParentAcc = new Account(Name = 'Opt_Acc', OptimizeID__c = '12345'); //ParentId = null
        Account nonOptimizeNonParentAcc = new Account(Name = 'Opt_Acc', ParentId = nonOptimizeAcc.Id); //ParentId != null
        
        insert new List<Account> {optimizeAcc, optimizeParentAcc, nonOptimizeNonParentAcc};
    }
    
    /**
	 * get all accounts
	 * @author Rajiv Ranjan
	 * @since June 2017
	 */
    private static List<Account> getAccounts()
    {
        return [Select Id, Name, ParentId From Account];
    }
    
    /**
	 * Test invalid request - case when either of optimizeid or account name is blank
	 * @author Rajiv Ranjan
	 * @since June 2017
	 */
    private static testMethod void test_Invalid_Request() {
        RestResponse res = executeTest('POST', null, 'Wrong_Name');
        
        //expecting a not found error here, so a 404 not found should be in the response
        System.assertEquals(400, res.statusCode, 'Expecting bad request error');
    }
    
    /**
	 * Test valid request - case when both of optimizeid and account name is existing
	 * @author Rajiv Ranjan
	 * @since June 2017
	 */
    private static testMethod void test_Existing_OptmizeAcc_And_ParentAcc() {
        List<Account> accs = getAccounts();
        RestResponse res = executeTest('POST', '1234', 'Opt_Acc');
         
        //assert response data
        System.assertEquals(200, res.statusCode, 'Expecting status code OK');
        
        ResponseHandler respData = (ResponseHandler) JSON.deserialize(res.responseBody.toString(), ResponseHandler.class);
        System.assertEquals('Re-parenting scuccessful!', respData.Message, 'success message');
        
        List<Account> accsProcessed = [Select Id, ParentId From Account Where optimizeId__c = '1234'];
        System.assert(accsProcessed.size() == 1, 'One record should be found');
        System.assertEquals(accs[1].Id, accsProcessed[0].Id, 'Account found for Optimize id - 1234');
        System.assertEquals(accs[2].Id, accsProcessed[0].ParentId, 'Parent found for account with Optimize id - 1234');
    }
    
    /**
	 * Test valid request - case when optimizeid is existing and account name is not
	 * @author Rajiv Ranjan
	 * @since June 2017
	 */
    private static testMethod void test_Existing_OptmizeAcc_NonExisting_ParentAcc() {
        List<Account> accs = getAccounts();
        RestResponse res = executeTest('POST', '1234', 'New_Acc');
        
        //assert response data
        System.assertEquals(200, res.statusCode, 'Expecting status code OK');
        
        ResponseHandler respData = (ResponseHandler) JSON.deserialize(res.responseBody.toString(), ResponseHandler.class);
        System.assertEquals('Re-parenting scuccessful!', respData.Message, 'success message');
        
        List<Account> accsProcessed = [Select Id, ParentId From Account Where optimizeId__c = '1234'];
        System.assert(accsProcessed.size() == 1, 'One record should be found');
        System.assertEquals(accs[1].Id, accsProcessed[0].Id, 'Account found for Optimize id - 1234');
        System.assert(accsProcessed[0].ParentId != null
                        && accs[0].Id != accsProcessed[0].ParentId
                        && accs[2].Id != accsProcessed[0].ParentId
                        && accs[3].Id != accsProcessed[0].ParentId
                        , 'Parent found should not be any of the existing accs');
    }
    
    /**
	 * Test valid request - case when optimizeid is not-existing and account name is existing
	 * @author Rajiv Ranjan
	 * @since June 2017
	 */
    private static testMethod void test_NonExisting_OptmizeAcc_Existing_ParentAcc() {
        List<Account> accs = getAccounts();
        RestResponse res = executeTest('POST', '12345678', 'Opt_Acc');
        
        //assert response data
        System.assertEquals(200, res.statusCode, 'Expecting status code OK');
        
        ResponseHandler respData = (ResponseHandler) JSON.deserialize(res.responseBody.toString(), ResponseHandler.class);
        System.assertEquals('Partial Re-parenting scuccessful!', respData.Message, 'success message');
        
        List<Account> accsProcessed = [Select Id, ParentId From Account Where ParentId != null And Name = 'Opt_Acc'];
        System.assert(accsProcessed.size() == 2, '2 records should be found, one existin and other new');
        
        System.assert(accs[0].Id != accsProcessed[1].Id
                        && accs[1].Id != accsProcessed[1].Id
                        && accs[2].Id != accsProcessed[1].Id
                        && accs[3].Id != accsProcessed[1].Id
                      , 'child record should not be any of the existing accs, It should be created new');
        System.assertEquals(accs[1].Id, accsProcessed[1].parentId, 'Parent Account found for newly created child');
    }
    
    //Left this case
    private static testMethod void test_NonExisting_OptmizeAcc_NonExisting_ParentAcc() {
    
    }
    
    /**
     * Common execute test method for all possible cases
     * 
     * @author Rajiv Ranjan
     * @since June 2017
     * @param uri request uri
     * @param httpMethod request method
     * @param requestBody request body json
     * @return rest response
     */
    private static RestResponse executeTest(String httpMethod, String optimizeId, String accName) {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/accountreparenting';
        
        //set method to use
        req.httpMethod = httpMethod;

        // set request params
        req.addParameter('OptimizeID', OptimizeID);
        req.addParameter('accName', accName);
        
        //initiate test
        RestContext.request = req;
        RestContext.response = res;
        
        System.Test.startTest();
        
        //call relevant method in class
        if(REQUEST_METHOD_POST == httpMethod) {
            AccountRestAPI.doPost(OptimizeID, accName);
        }
        
        System.Test.stopTest();

        return res;
    }
}