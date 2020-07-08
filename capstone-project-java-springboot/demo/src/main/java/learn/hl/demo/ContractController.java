package learn.hl.demo;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class ContractController {
    @GetMapping({"/contract", "/hello"})
    public String hello(Model model) {
        // model.addAttribute("name", name);
        return "contract";
    }

    @PostMapping("/albums/create")
    @ResponseBody
    public String create(Model model, @RequestParam String contractfor) throws Exception {
        MediaContract.Create(contractfor);
        return "contract created successfully";
    }

        @PostMapping("/albums/create2")
    @ResponseBody
    public String create2(Model model, @RequestParam String contractfor) throws Exception {
        MediaContract.Create2(contractfor);
        return "contract created successfully";
    }
}