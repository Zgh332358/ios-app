import UIKit
import Combine

class SettingsController: UITableViewController {
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = SettingsViewModel()

    private enum Section: Int, CaseIterable {
        case network
        case about
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        viewModel.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section) == .network ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section) == .network ? "Web App" : "About"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .network else { return nil }
        return "填写你部署的共鸣网页地址。API Key 和模型在网页服务端配置。留空使用构建时的网页地址；默认构建未配置地址。"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        if Section(rawValue: indexPath.section) == .network {
            cell.textLabel?.text = "Web App URL"
            cell.detailTextLabel?.text = viewModel.settings.endpoint ?? "Use build configuration"
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.row == 0 {
            cell.textLabel?.text = "Version"
            cell.detailTextLabel?.text = viewModel.appVersion
            cell.selectionStyle = .none
        } else {
            cell.textLabel?.text = "Source Code"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Section(rawValue: indexPath.section) == .network {
            showEndpointEditor()
        } else if indexPath.row == 1,
                  let url = URL(string: "https://github.com/Zgh332358/ios-app") {
            UIApplication.shared.open(url)
        }
    }

    private func showEndpointEditor() {
        let alert = UIAlertController(title: "Web App URL",
                                      message: "输入你部署的共鸣网页 HTTPS 地址，不是 StepFun 官网 API base URL。",
                                      preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            textField.text = self?.viewModel.settings.endpoint
            textField.placeholder = "https://your-resonance.example.com"
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.viewModel.setEndpoint(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
