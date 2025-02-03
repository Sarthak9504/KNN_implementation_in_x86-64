input_file_path = 'incomePred_test2.csv'
output_file_path = 'output2.csv'

with open(input_file_path, 'r') as input_file:
    input_lines = [line.strip() for line in input_file if line.strip()]

with open(output_file_path, 'r') as output_file:
    output_lines = [line.strip() for line in output_file if line.strip()]

    correct_predictions = 0
    true_positive = 0
    true_negative = 0
    false_positive = 0
    false_negative = 0
    precision = 0.00
    recall = 0.00
    f1_Score = 0.00

    for i in range(len(input_lines)):
        input_line = input_lines[i].split(',')
        output_line = output_lines[i]
        if input_line[-1] == output_line:
            correct_predictions += 1
            if output_line == "100":
                true_positive += 1
            elif output_line == "000":
                true_negative += 1
        else:
            if input_line[-1] == "000" and output_line == "100":
                false_positive += 1
            elif input_line[-1] == "100" and output_line == "000":
                false_negative += 1

    accuracy = (correct_predictions / len(input_lines)) * 100
    precision = (true_positive / (true_positive + false_positive)) * 100
    recall = (true_positive / (true_positive + false_negative)) * 100
    f1_score = ((2 * precision * recall) / (precision + recall))

    print(f"Total number of individuals: {len(input_lines)}")
    print(f"Number of correct predictions: {correct_predictions}")
    print(f"Accuracy: {accuracy:.2f}%")
    # print(f"Precision: {precision:.2f}%")
    # print(f"Recall: {recall:.2f}%")
    # print(f"F1-Score: {f1_Score:.2f}%")
    # print(f"True Positive(Income Greater than 50K): {true_positive}")
    # print(f"True Negative(Income Less than 50K): {true_negative}")
    print(f"Total number of predictions with income >50K: {true_positive + false_positive}")
    print(f"Total number of predictions with income <50K: {true_negative + false_negative}")
    # print(f"False Positive(Income Less than 50K but predicted greater than 50K): {false_positive}")
    # print(f"False Negative(Income greater than 50K but predicted Less than 50K): {false_negative}")
