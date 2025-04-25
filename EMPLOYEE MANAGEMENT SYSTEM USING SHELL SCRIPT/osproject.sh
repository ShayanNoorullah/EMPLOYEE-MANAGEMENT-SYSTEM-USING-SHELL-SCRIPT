#!/bin/bash

COMPANY_FILE="company.txt"
FINANCE_FILE="finance.txt"
HR_FILE="human_resources.txt"
OPERATIONS_FILE="operation_management.txt"
MARKETING_FILE="marketing.txt"
IT_FILE="information_technology.txt"
FIRED_EMPLOYEE_FILE="fired.txt"
RETIRED_EMPLOYEE_FILE="retired.txt"

generate_employee_number() {
    next_id=2
    while true; do
        id=$(printf "%05d" "$next_id")
        found=false
        for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
            if grep -q "^$id " "$file"; then
                found=true && break
            fi
        done
        if ! $found; then
            break
        fi
        ((next_id++))
    done

    number_of_employee=$(printf "%05d" "$next_id")
    echo "$number_of_employee"
}

display_menu() {
    zenity --list --title="Employee Management System" --column="Option" --column="Department" \
    "1" "Company Data" \
    "2" "Finance Department Data" \
    "3" "Human Resources Department Data" \
    "4" "Operational Management Department Data" \
    "5" "Marketing Department Data" \
    "6" "Information Technology Department Data" \
    "7" "Back To Main Menu" \
    --height=400 \
    --width=600
}

display_print_menu(){
    zenity --list --title="Employee Management System" --column="Option" --column="Department" \
    "1" "Company Data" \
    "2" "Finance Department Data" \
    "3" "Human Resources Department Data" \
    "4" "Operational Management Department Data" \
    "5" "Marketing Department Data" \
    "6" "Information Technology Department Data" \
    "7" "Retired Employee Data" \
    "8" "Fired Employee Data"\
    "9" "Back To Main Menu" \
    --height=400 \
    --width=600
}
display_operations_menu() {
    zenity --list --title="Employee Management System" --column="Option" --column="Operation" \
    "1" "Insert record" \
    "2" "Delete record" \
    "3" "Update record" \
    "4" "Search record" \
    "5" "Print Content" \
    "6" "Count Employees" \
    "7" "Transfer Employee" \
    "8" "Promote Employee" \
    --height=400 \
    --width=600
}

display_employee_number_menu() {
    zenity --list --title="Employee Management System" --column="Option" --column="Count Employees" \
    "1" "Count Of All Employees" \
    "2" "Count Of All Departmental Employees" \
    "3" "Count Of All specific Department Employees" \
    "4" "Back To Main Menu" \
    --height=400 \
    --width=600
}

count_employee() {
    choice=$(display_employee_number_menu)
    case $choice in
        1)
            total_employees=0
            for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
                count=$(wc -l < "$file") && total_employees=$((total_employees + count))
            done
            zenity --info --title="Total Employees" --text="Total Number of Employees: $total_employees"
            ;;
        2)
            total_employees=0
            for file in "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
                count=$(wc -l < "$file") && total_employees=$((total_employees + count))
            done
            zenity --info --title="Total Employees" --text="Total Number of Employees in all Departments (excluding Company): $total_employees"
            ;;
        3)
            department=$(display_menu)
            case $department in
                "1") file="$COMPANY_FILE";;
                "2") file="$FINANCE_FILE";;
                "3") file="$HR_FILE";;
                "4") file="$OPERATIONS_FILE";;
                "5") file="$MARKETING_FILE";;
                "6") file="$IT_FILE";;
                *) zenity --error --title="Error" --text="Invalid department"; return;;
            esac

            if [[ -f "$file" ]]; then
                count=$(wc -l < "$file")
                zenity --info --title="Total Employees" --text="Total Number of Employees in $(basename "$file"): $((count))"
            else
                zenity --error --title="Error" --text="File not found: $file"
            fi
            ;;
        4)  return;;
        *) zenity --error --title="Error" --text="Invalid choice"; return;;
    esac
}

search_cnic() {
    local cnic="$1"
    local found=false

    for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
        file_contents=$(<"$file")
        if echo "$file_contents" | grep -q "^.* $cnic "; then
            found=true && break
        fi
    done

    echo "$found"
}

insert_record() {
    fields=$(zenity --forms --title="Insert Employee Record" --text="Enter employee data" --add-entry="First Name" --add-entry="Last Name" --add-entry="Position" --add-entry="Age" --add-entry="Salary" --add-entry="Phone" --add-entry="CNIC" --add-entry="Address")
    read -r fn ln position age salary phone cnic address <<< "$fields"

    if [[ $(search_cnic "$cnic") == true ]]; then
        zenity --error --title="Error" --text="Record with CNIC $cnic already exists."
        return
    fi

    department=$(display_menu)
    case $department in
        "1") file="$COMPANY_FILE";;
        "2") file="$FINANCE_FILE";;
        "3") file="$HR_FILE";;
        "4") file="$OPERATIONS_FILE";;
        "5") file="$MARKETING_FILE";;
        "6") file="$IT_FILE";;
        "7") return;;
        *) zenity --error --title="Error" --text="Invalid department"; return;;
    esac

    employee_number=$(generate_employee_number)
    # Replace '|' with spaces
    record="$employee_number $fn $ln $position $age $salary $phone $cnic $address" && record=$(echo "$record" | tr '|' ' ') && echo "$record" >> "$file"
    zenity --info --title="Success" --text="Record inserted successfully in $(basename "$file")."
}

delete_record() {
    id=$(zenity --entry --title="Delete Employee Record" --text="Enter ID of employee to delete:")
    if [[ -z $id ]]; then
        zenity --error --title="Error" --text="ID cannot be empty." && return
    fi

    local deleted=false

    for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
        if grep -q "^$id " "$file"; then
            grep "^$id " "$file" >> fired.txt && sed -i "/^$id/d" "$file"
            zenity --info --title="Success" --text="Record deleted successfully from $(basename "$file")."
            deleted=true
        fi
    done

    if ! $deleted; then
        zenity --error --title="Error" --text="Record with ID $id does not exist."
    fi
}
update_record() {
    id=$(zenity --entry --title="Update Employee Record" --text="Enter ID of employee to update:")
    if [[ -z $id ]]; then
        zenity --error --title="Error" --text="ID cannot be empty." && return
    fi

    new_data=$(zenity --entry --title="Update Employee Record" --text="Enter updated data (First-Name Last-Name Position Age Salary Phone-Number CNIC Address):")
    if [[ -z $new_data ]]; then
        zenity --error --title="Error" --text="Updated data cannot be empty." && return
    fi


    if grep -q " $new_data" "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; then
        zenity --error --title="Error" --text="Record with CNIC $new_data already exists. Invalid input. Please try again."
        return
    fi

    found=false
    for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
        if grep -q "^$id " "$file"; then
            sed -i "s/^$id.*/$id $new_data/" "$file" && zenity --info --title="Success" --text="Record updated successfully in $(basename "$file")." && found=true
        fi
    done

    if [[ ! $found ]]; then
        zenity --error --title="Error" --text="Record with ID $id not found in any file."
    fi
}
search_record_by_id() {
    while true; do
        id=$(zenity --entry --title="Search Employee Record" --text="Enter ID of employee to search:")
         if [[ $? -ne 0 ]]; then
            break
        fi
        
        if [[ -z $id ]]; then
            zenity --error --title="Error" --text="ID cannot be empty." && continue
        fi

        found=false
        for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
            if grep -q "^$id " "$file"; then
                record=$(grep "^$id " "$file") && zenity --info --title="Record Found" --text="Record with ID $id found in $(basename "$file"):\n$record" && found=true
            fi
        done

        if ! $found; then
            zenity --error --title="Error" --text="Record with ID $id not found in any file." && continue
        else
            break
        fi
    done
}


search_record_by_name() {
    while true; do
        fields=$(zenity --forms --title="Search Employee Record" --text="Enter employee's name" --add-entry="First Name" --add-entry="Last Name")
        
        if [[ -z $fields ]]; then
            zenity --error --title="Error" --text="Search cancelled." && break
        fi

        read -r first_name last_name <<< "$(echo "$fields" | tr '|' ' ')"

        if [[ -z $first_name ]] || [[ -z $last_name ]]; then
            zenity --error --title="Error" --text="First name and last name cannot be empty." && continue
        fi

        found=false
        for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
            if grep -qi "^.* $first_name $last_name " "$file"; then
                record=$(grep -i "^.* $first_name $last_name " "$file") && zenity --info --title="Record Found" --text="Record found in $(basename "$file"):\n$record" && found=true
            fi
        done

        if ! $found; then
            zenity --error --title="Error" --text="Record with name $first_name $last_name not found in any file." && continue
        else
            break
        fi
    done
}

search_record() {
    search_option=$(zenity --list --title="Search Employee Record" --text="Select search option:" --column="Option" --column="Type" \
   "1" "ID" \
   "2" "Name" \
    --height=400 \
    --width=600)
    
    case $search_option in
        "1") search_record_by_id;;
        "2") search_record_by_name;;
        *) return;;
    esac
}
print_record() {
  choice=$(display_print_menu)
  case $choice in
    1) file="$COMPANY_FILE";;
    2) file="$FINANCE_FILE";;
    3) file="$HR_FILE";;
    4) file="$OPERATIONS_FILE";;
    5) file="$MARKETING_FILE";;
    6) file="$IT_FILE";;
    7) file="$RETIRED_EMPLOYEE_FILE"
    	options=""
  while IFS= read -r line; do
    options+="$line "
  done < "$file"

  zenity --list --title="Employee Records" \
    --text="Records Of $file" \
    --column="ID" --column="First Name" --column="Last Name" --column="Position" --column="Age" --column="Salary" --column="Phone Number" --column="CNIC" --column="Address" --column="pension"\
    $options \
    --width=1500 --height=600; return;;
    8) file="$FIRED_EMPLOYEE_FILE";;
    7) return;;
    *) zenity --error --title="Error" --text="Invalid choice"; return;;
  esac

 options=""
  while IFS= read -r line; do
    options+="$line "
  done < "$file"

  zenity --list --title="Employee Records" \
    --text="Records Of $file" \
    --column="ID" --column="First Name" --column="Last Name" --column="Position" --column="Age" --column="Salary" --column="Phone Number" --column="CNIC" --column="Address" \
    $options \
    --width=1500 --height=600
}



transfer_employee() {
    zenity --entry --title="Employee Transfer" --text="Enter ID of employee to transfer:" --entry-text="" |
    while read -r id; do
        if [[ -z $id ]]; then
            zenity --error --title="Error" --text="Please enter a valid ID." && continue
        fi

        local record department
        for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
        	if grep -q "^$id " "$file"; then
			record=$(grep "^$id " "$file") && department=$(basename "$file" ".txt") && break
        	fi
	done

        if [[ -z $record ]]; then
            zenity --error --title="Error" --text="Record with ID $id not found." && continue
        fi


        choice=$(display_menu)
        case $choice in
            1) new_file="$COMPANY_FILE";;
            2) new_file="$FINANCE_FILE";;
            3) new_file="$HR_FILE";;
            4) new_file="$OPERATIONS_FILE";;
            5) new_file="$MARKETING_FILE";;
            6) new_file="$IT_FILE";;
            7) return;;
            *) zenity --error --title="Error" --text="Invalid department"; continue;;
        esac

        if [[ "$file" != "$new_file" ]]; then
  
            sed -i "/^$id /d" "$file"
            current_salary=$(echo "$record" | awk '{print $6}') && current_designation=$(echo "$record" | awk '{print $4}')

            update_salary=$(zenity --entry --title="Update Salary?" --text="Do you want to update the salary? (y/n)" --entry-text="")
            if [[ $update_salary == "y" ]]; then
                new_salary=$(zenity --entry --title="Enter New Salary" --text="Enter new salary:" --entry-text="$current_salary")
            else
                new_salary=$current_salary
            fi

            update_designation=$(zenity --entry --title="Update Designation?" --text="Do you want to update the designation? (y/n)" --entry-text="")
            if [[ $update_designation == "y" ]]; then
                new_designation=$(zenity --entry --title="Enter New Designation" --text="Enter new designation:" --entry-text="$current_designation")
            else
                new_designation=$current_designation
            fi

            record=$(echo "$record" | awk -v new_salary="$new_salary" -v new_designation="$new_designation" '{$4=new_designation; $6=new_salary; print}')
            
           if [[  "$new_designation" == "Head-of-"* || "$new_designation" == "head-of-"* || "$new_designation" == "HEAD-OF-"* ]]; then
    
            pension=$(zenity --entry --title="Promote Employee" --text="Enter pension amount for the previous retired head:")
    
            if [[ -z $pension ]]; then
              zenity --error --text="Pension amount cannot be empty."
              return
            fi
    
            line_numbers=$(grep -in "$new_designation" "$COMPANY_FILE" | cut -d: -f1)
            if [[ -n $line_numbers ]]; then
    
            for line_number in $line_numbers; do 
            line_content=$(sed -n "${line_number}p" "$COMPANY_FILE") 
            echo "$line_content $pension" >> retired.txt
        
           sed -i "${line_number}d" "$COMPANY_FILE"
    done
fi 
fi 
       
            echo "$record" >> "$new_file"
            zenity --info --title="Success" --text="Record transferred successfully to $(basename "$new_file")."
        else
            zenity --info --title="Information" --text="Employee is already in the selected department."
        fi
    done
}

promote_employee() {
    zenity --entry --title="Employee Promotion" --text="Enter ID of employee to update:" --entry-text="" |
    while read -r id; do
        if [[ -z $id ]]; then
            zenity --error --title="Error" --text="Please enter a valid ID." && continue
        fi

        local record department
        for file in "$COMPANY_FILE" "$FINANCE_FILE" "$HR_FILE" "$OPERATIONS_FILE" "$MARKETING_FILE" "$IT_FILE"; do
        	if grep -q "^$id " "$file"; then
			record=$(grep "^$id " "$file") && department=$(basename "$file" ".txt") && break
        	fi
	done

        if [[ -z $record ]]; then
            zenity --error --title="Error" --text="Record with ID $id not found." && continue
        fi

        new_designation=$(zenity --entry --title="Enter New Designation" --text="Enter new designation:" --entry-text="")

        update_salary=$(zenity --entry --title="Update Salary?" --text="Do you want to update the salary? (y/n)" --entry-text="")
        if [[ $update_salary == "y" ]]; then
            new_salary=$(zenity --entry --title="Enter New Salary" --text="Enter new salary:" --entry-text="")
        else
            new_salary=$(echo "$record" | awk '{print $6}')
        fi

        record=$(echo "$record" | awk -v new_salary="$new_salary" -v new_designation="$new_designation" '{$4=new_designation; $6=new_salary; print}')

        sed -i "s/^$id.*/$record/" "$file"
        zenity --info --title="Success" --text="Record updated successfully in $(basename "$file")."

        if [[ $new_designation == Head-of-* || $new_designation == head-of-* || $new_designation == HEAD-OF-* ]]; then
       
            pension=$(zenity --entry --title="Promote Employee" --text="Enter pension amount  for the previous retired head:")
    
            if [[ -z $pension ]]; then
             zenity --error --text="Pension amount cannot be empty."
             return
            fi
    
            line_numbers=$(grep -in "$new_designation" "$COMPANY_FILE" | cut -d: -f1)
          if [[ -n $line_numbers ]]; then
    
           for line_number in $line_numbers; do
           line_content=$(sed -n "${line_number}p" "$COMPANY_FILE") 
           echo "$line_content $pension" >> retired.txt
        
           sed -i "${line_number}d" "$COMPANY_FILE"
           done
         fi
            echo "$record" >> "$COMPANY_FILE"
            zenity --info --title="Success" --text="Record added to company.txt as well."

            sed -i "/^$id /d" "$file" && zenity --info --title="Success" --text="Record deleted from $(basename "$file")."
        fi
    done
}

#################
while true; do
    operation=$(display_operations_menu)
    if [ $? -ne 0 ]; then 
        exit
    fi

    case $operation in
        1) insert_record;;
        2) delete_record;;
        3) update_record;;
        4) search_record;;
        5) print_record;;
        6) count_employee;;
        7) transfer_employee;;
        8) promote_employee;;
        *) zenity --error --title="Error" --text="Invalid choice";;
    esac
done
