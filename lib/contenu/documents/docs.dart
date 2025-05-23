import 'package:flutter/material.dart';
import '../../widgets/navbar.dart';

class SuiviAdministratifPage extends StatelessWidget {
  const SuiviAdministratifPage({super.key});

  @override
  Widget build(BuildContext context) {
    final taches = [
      const TacheCard(
        titre: 'Renouvellement carte d\'identité',
        echeance: '15/06/2025',
        statut: 'Urgent',
        description: 'Action requise rapidement',
        couleur: Colors.red,
      ),
      const TacheCard(
        titre: 'Paiement taxe d\'habitation',
        echeance: '30/11/2025',
        statut: 'À faire',
        couleur: Colors.grey,
      ),
      const TacheCard(
        titre: 'Déclaration d\'impôts',
        echeance: '05/06/2025',
        statut: 'Complété',
        couleur: Colors.green,
        completed: true,
      ),
      const TacheCard(
        titre: 'Mise à jour CV',
        echeance: '10/05/2025',
        statut: 'Complété',
        couleur: Colors.green,
        completed: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Color(0xFF8B5CF6), size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Suivi Administratif',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Gérez vos démarches et obligations administratives.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Tâches administratives', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Gardez une trace de vos obligations administratives et rendez-vous importants.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle tâche'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé des tâches',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Tâches pour ce mois', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('2/4 complétées', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Colors.grey,
                    color: Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: taches.map((card) {
                    return SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 2 : double.infinity,
                      child: card,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TacheCard extends StatelessWidget {
  final String titre;
  final String echeance;
  final String statut;
  final String? description;
  final Color couleur;
  final bool completed;

  const TacheCard({
    super.key,
    required this.titre,
    required this.echeance,
    required this.statut,
    required this.couleur,
    this.description,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: couleur.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statut,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: couleur,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Échéance: $echeance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600)),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: couleur),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(description!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: couleur)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: completed ? null : () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Marquer comme complété'),
            ),
          )
        ],
      ),
    );
  }
}
