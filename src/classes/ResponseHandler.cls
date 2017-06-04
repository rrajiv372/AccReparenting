/**
* Class used to represent response data, return object data can also be added if required
*
* @author Rajiv Ranjan
* @since June 2017
*/
public class ResponseHandler {
    public String Status {get; set;}
    public String Message {get;set;}
    
    public ResponseHandler(String Status, String Message) {
        this.Status = Status;
        this.Message = Message;
    }
}